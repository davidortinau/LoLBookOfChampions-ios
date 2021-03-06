//
// NIOContentResolver / LoLBookOfChampions
//
// Created by Jeff Roberts on 2/3/15.
// Copyright (c) 2015 Riot Games. All rights reserved.
//


#import "NIOContentResolver.h"
#import "NIOBaseContentProvider.h"
#import "NIOContentProviderFactory.h"
#import "NIOContentObserver.h"
#import <Bolts/Bolts.h>

#define CONTENT_AUTHORITY(REGISTRATION_PATH)    [NSString stringWithFormat:@"content://%@.%@", self.contentAuthorityBase, REGISTRATION_PATH]

@interface ContentObserverRegistration : NSObject
@property (strong, nonatomic) id<NIOContentObserver>contentObserver;
@property (strong, nonatomic) NSURL *contentURI;
@property (assign, nonatomic) BOOL notifyForDescendents;

-(instancetype)init;
@end

@implementation ContentObserverRegistration
-(instancetype)init {
	self = [super init];
	if ( self ) {}
	return self;
}

-(BOOL)isEqual:(id)other {
	if ( other == self )
		return YES;
	if ( !other || ![[other class] isEqual:[self class]] )
		return NO;

	ContentObserverRegistration *otherRegistration = (ContentObserverRegistration *)other;
	return [self.contentURI isEqual:otherRegistration.contentURI];
}

@end


@interface NIOContentResolver ()
@property (strong, nonatomic) NSMutableDictionary *activeContentProviderRegistry;
@property (strong, nonatomic) NSString *contentAuthorityBase;
@property (strong, nonatomic) NSMutableDictionary *contentObservers;
@property (strong, nonatomic) id <NIOContentProviderFactory> contentProviderFactory;
@property (strong, nonatomic) NSDictionary *contentRegistrations;
@property (strong, nonatomic) BFExecutor *executionExecutor;
@property (strong, nonatomic) BFExecutor *completionExecutor;
@end

@implementation NIOContentResolver
-(instancetype)initWithContentProviderFactory:(id <NIOContentProviderFactory>)factory
					 withContentAuthorityBase:(NSString *)contentAuthorityBase
							withRegistrations:(NSDictionary *)registrations
						   withExecutionQueue:(dispatch_queue_t)executionQueue
						  withCompletionQueue:(dispatch_queue_t)completionQueue {
	self = [super init];
	if ( self ) {
		self.contentProviderFactory = factory;
		self.contentAuthorityBase = contentAuthorityBase;
		self.contentRegistrations = registrations;
		self.activeContentProviderRegistry = [NSMutableDictionary new];
		self.executionExecutor = [BFExecutor executorWithDispatchQueue:executionQueue];
		self.completionExecutor = [BFExecutor executorWithDispatchQueue:completionQueue];
		self.contentObservers = [NSMutableDictionary new];
		[self initialize];
	}

	return self;
}

-(void)initialize {
	[self initializeRegistrations];
}

-(void)initializeRegistrations {
	// Replace the registrations by generating absolute content URL strings
	NSMutableDictionary *newRegistrations = [NSMutableDictionary new];
	for ( NSString *registrationPath in self.contentRegistrations.allKeys ) {
		NSString *newKey = CONTENT_AUTHORITY(registrationPath);
		newRegistrations[newKey] = self.contentRegistrations[registrationPath];
	}

	self.contentRegistrations = newRegistrations;
}

-(id <NIOContentProvider>)getContentProviderForContentURI:(NSURL *)contentURI {
	NSString *contentAuthority = [self getContentAuthorityForContentURI:contentURI];
	id <NIOContentProvider> activeContentProvider = self.activeContentProviderRegistry[contentAuthority];
	if ( activeContentProvider == nil ) {
		NSString *className = self.contentRegistrations[contentAuthority];
		Class contentProviderClass = className ? NSClassFromString(className) : nil;
		activeContentProvider = contentProviderClass ?
								[self.contentProviderFactory createContentProviderWithType:contentProviderClass] :
								nil;
		if ( activeContentProvider ) {
			((NIOBaseContentProvider *) activeContentProvider).contentResolver = self;
			[((NIOBaseContentProvider *) activeContentProvider) onCreate];
			self.activeContentProviderRegistry[contentAuthority] = activeContentProvider;
		}
	}

	return activeContentProvider;
}

-(NSString *)getContentAuthorityForContentURI:(NSURL *)contentURI {
	__weak __block NSString *contentURIString = [contentURI absoluteString];
	NSArray *registrationURIs = [self.contentRegistrations allKeys];
	NSIndexSet *indexSet = [registrationURIs indexesOfObjectsPassingTest:^BOOL(NSString *urlString, NSUInteger idx, BOOL *stop) {
		if ( [contentURIString hasPrefix:urlString] ) {
			*stop = YES;
			return YES;
		}

		return NO;
	}];

	return indexSet.count > 0 ? registrationURIs[indexSet.firstIndex] : nil;
}

-(void)notifyChange:(NSURL *)contentURI {
	__weak NIOContentResolver *weakSelf = self;
	[self.completionExecutor execute:^{
		NSString *contentURIString = [contentURI absoluteString];
		for ( NSString *key in weakSelf.contentObservers.allKeys ) {
			NSArray *registrations = weakSelf.contentObservers[key];

			for ( ContentObserverRegistration *registration in registrations ) {
				BOOL shouldNotify = [[registration.contentURI absoluteString] isEqual:contentURIString] ||
						(registration.notifyForDescendents && [contentURIString hasPrefix:[registration.contentURI absoluteString]]);
				if ( shouldNotify ) {
					[registration.contentObserver onUpdate:contentURI];
				}
			}
		}
	}];
}

-(void)registerContentObserverWithContentURI:(NSURL *)contentUri
					withNotifyForDescendents:(bool)notifyForDescendents
						 withContentObserver:(id <NIOContentObserver>)contentObserver {
	NSString *key = NSStringFromClass([contentObserver class]);
	NSMutableArray *registrations = self.contentObservers[key];
	if ( !registrations ) {
		registrations = [NSMutableArray new];
		self.contentObservers[key] = registrations;
	}

	ContentObserverRegistration *registration = [ContentObserverRegistration new];
	registration.contentObserver = contentObserver;
	registration.contentURI = contentUri;
	registration.notifyForDescendents = notifyForDescendents;

	if ( ![registrations containsObject:registration] ) {
		[registrations addObject:registration];
	}
}

-(void)unregisterContentObserver:(id <NIOContentObserver>)contentObserver {
	NSString *key = NSStringFromClass([contentObserver class]);
	[self.contentObservers removeObjectForKey:key];
}

-(BFTask *)deleteWithURI:(NSURL *)uri withSelection:(NSString *)selection withSelectionArgs:(NSArray *)selectionArgs {
	return [[BFTask taskFromExecutor:self.executionExecutor withBlock:^id {
		NSError *error;
		NSInteger deleteCount = [[self getContentProviderForContentURI:uri]
				deleteWithURI:uri
				withSelection:selection
			withSelectionArgs:selectionArgs
					withError:&error];
		return error ? [BFTask taskWithError:error] : [BFTask taskWithResult:@(deleteCount)];
	}] continueWithExecutor:self.completionExecutor withBlock:^id(BFTask *task) {
		return task;
	}];
}

-(BFTask *)insertWithURI:(NSURL *)uri withValues:(NSDictionary *)values {
	return [[BFTask taskFromExecutor:self.executionExecutor withBlock:^id {
		NSError *error;
		NSURL *insertedURI = [[self getContentProviderForContentURI:uri]
				insertWithURI:uri
				   withValues:values
					withError:&error];
		return error ? [BFTask taskWithError:error] : [BFTask taskWithResult:insertedURI];
	}] continueWithExecutor:self.completionExecutor withBlock:^id(BFTask *task) {
		return task;
	}];
}

-(BFTask *)queryWithURI:(NSURL *)uri
		 withProjection:(NSArray *)projection
		  withSelection:(NSString *)selection
	  withSelectionArgs:(NSArray *)selectionArgs
			withGroupBy:(NSString *)groupBy
			 withHaving:(NSString *)having
			   withSort:(NSString *)sort {

	return [[BFTask taskFromExecutor:self.executionExecutor withBlock:^id {
		NSError *error;
		id<NIOCursor> cursor = [[self getContentProviderForContentURI:uri]
				queryWithURI:uri
			  withProjection:projection
			   withSelection:selection
		   withSelectionArgs:selectionArgs
				 withGroupBy:groupBy
				  withHaving:having
					withSort:sort
				   withError:&error];
		return error ? [BFTask taskWithError:error] : [BFTask taskWithResult:cursor];
	}] continueWithExecutor:self.completionExecutor withBlock:^id(BFTask *task) {
		return task;
	}];
}

-(BFTask *)updateWithURI:(NSURL *)uri withSelection:(NSString *)selection withSelectionArgs:(NSArray *)selectionArgs {
	return [[BFTask taskFromExecutor:self.executionExecutor withBlock:^id {
		NSError *error;
		NSInteger updateCount = [[self getContentProviderForContentURI:uri]
				updateWithURI:uri
				withSelection:selection
			withSelectionArgs:selectionArgs
					withError:&error];
		return error ? [BFTask taskWithError:error] : [BFTask taskWithResult:@(updateCount)];

	}] continueWithExecutor:self.completionExecutor withBlock:^id(BFTask *task) {
		return task;
	}];
}


@end