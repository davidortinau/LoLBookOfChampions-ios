//
// Created by Jeff Roberts on 1/23/15.
// Copyright (c) 2015 nimbleNoggin.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIOTask.h"

@class NIOLoLApiRequestOperationManager;

@interface NIOGetRealmTask : NSObject<NIOTask>
-(instancetype)initWithHTTPRequestOperationManager:(NIOLoLApiRequestOperationManager *)apiRequestOperationManager;
@end