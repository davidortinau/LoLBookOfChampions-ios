//
// Created by Jeff Roberts on 1/24/15.
// Copyright (c) 2015 nimbleNoggin.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GetRealmTask;
@protocol ContentProvider;


@interface NIODataDragonSyncService : NSObject
-(instancetype)initWithContentProvider:(id<ContentProvider>)contentProvider
					  withGetRealmTask:(GetRealmTask *)getRealmTask;
-(void)sync;
@end