//
// Created by Jeff Roberts on 2/15/15.
// Copyright (c) 2015 io.nimblenoggin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIOBaseSQLTask.h"
#import "NIOTask.h"


@interface NIOInsertChampionTask : NIOBaseSQLTask <NIOTask>
-(instancetype)initWithDatabase:(FMDatabase *)database;
@end