//
// NIOBaseSQLQueryTask / LoLBookOfChampions
//
// Created by Jeff Roberts on 2/14/15.
// Copyright (c) 2015 Riot Games. All rights reserved.
//


#import "NIOBaseSQLQueryTask.h"
#import "NIOCursor.h"
#import "NIOSqliteCursor.h"

#define PROJECTION_ALL		@"*"

@implementation NIOBaseSQLQueryTask
-(instancetype)initWithDatabase:(FMDatabase *)database {
	self = [super initWithDatabase:database];
	if ( self ) {
	}

	return self;
}

-(BFTask *)asQueryResult:(FMResultSet *)queryResultSet {
	FMResultSet *countResultSet = [self executeCountQuery];
	int rowCount = 0;
	if ( countResultSet ) {
		if ( [countResultSet next] ) {
			rowCount = [countResultSet intForColumnIndex:0];
		}
		[countResultSet close];
	}

	return [self asQueryResult:queryResultSet withRowCount:(uint)rowCount];
}

-(BFTask *)asQueryResult:(FMResultSet *)queryResultSet withRowCount:(uint)rowCount {
	return queryResultSet ?
		   [BFTask taskWithResult:[[NIOSqliteCursor alloc] initWithResultSet:queryResultSet withRowCount:rowCount]] :
		   [BFTask taskWithError:self.database.lastError];
}

-(NSString *)createProjection:(NSArray *)projection {
	return projection && projection.count ? [projection componentsJoinedByString:@","] : PROJECTION_ALL;
}

-(FMResultSet *)executeCountQuery {
	return [self executeQueryWithProjection:@[COUNT]];
}

-(FMResultSet *)executeQuery {
	return [self executeQueryWithProjection:self.projection];
}


-(FMResultSet *)executeQueryWithProjection:(NSArray *)projection {
	NSMutableString *sqlStatement = [NSMutableString new];
	[sqlStatement appendString:SELECT];
	[sqlStatement appendString:[self createProjection:projection]];
	[sqlStatement appendString:FROM];
	[sqlStatement appendString:self.table];

	if ( self.selection && self.selection.length ) {
		[sqlStatement appendString:WHERE];
		[sqlStatement appendString:self.selection];
	}

	if ( self.groupBy && self.groupBy.length ) {
		[sqlStatement appendString:GROUP_BY];
		[sqlStatement appendString:self.groupBy];
	}

	if ( self.having && self.having.length ) {
		[sqlStatement appendString:HAVING];
		[sqlStatement appendString:self.having];
	}

	if ( self.sort && self.sort.length ) {
		[sqlStatement appendString:ORDER_BY];
		[sqlStatement appendString:self.sort];
	}

	return self.selectionArgs ? [self.database executeQuery:sqlStatement
									   withArgumentsInArray:self.selectionArgs] :
		   [self.database executeQuery:sqlStatement];
}
@end