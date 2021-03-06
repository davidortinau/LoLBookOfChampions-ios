//
// Created by Jeff Roberts on 1/23/15.
// Copyright (c) 2015 nimbleNoggin.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Typhoon/TyphoonAssembly.h>
#import <FMDB/FMDB.h>

@class NIOLoLApiRequestOperationManager;
@class NIOGetRealmTask;
@class NIODataDragonSyncService;
@protocol NIOContentProvider;
@class NIOCoreComponents;
@class NIODataDragonContentProvider;
@class NIODataDragonSqliteOpenHelper;
@class NIOQueryRealmsTask;
@class NIODeleteRealmTask;
@class NIOClearLocalDataDragonDataTask;
@class NIOInsertRealmTask;
@class NIOInsertDataDragonRealmTask;
@class NIOGetChampionStaticDataTask;
@class NIODeleteChampionTask;
@class NIODeleteChampionSkinTask;
@class NIOInsertChampionTask;
@class NIOInsertChampionSkinTask;
@class NIODataDragonCDNRequestOperationManager;
@class NIOInsertDataDragonChampionDataTask;
@class NIOCacheChampionImagesTask;
@class NIOQueryChampionsTask;
@class NIOQueryChampionSkinsTask;

@interface NIODataDragonComponents : TyphoonAssembly
@property (nonatomic, strong, readonly) NIOCoreComponents *coreComponents;

-(NIOCacheChampionImagesTask *)cacheChampionImagesTask;
-(NIOClearLocalDataDragonDataTask *)clearLocalDataDragonDataTask;
-(NIODataDragonCDNRequestOperationManager *)dataDragonCDNRequestOperationManager;
-(NIODataDragonContentProvider *)dataDragonContentProvider;
-(FMDatabase *)dataDragonSqliteDatabase;
-(NIODataDragonSqliteOpenHelper *)dataDragonSqliteOpenHelper;
-(NIODataDragonSyncService *)dataDragonSyncService;
-(NIODeleteChampionTask *)deleteChampionTask;
-(NIODeleteChampionSkinTask *)deleteChampionSkinTask;
-(NIODeleteRealmTask *)deleteRealmsTask;
-(NIOGetChampionStaticDataTask *)getChampionStaticDataTask;
-(NIOGetRealmTask *)getRealmTask;
-(NIOInsertChampionTask *)insertChampionTask;
-(NIOInsertChampionSkinTask *)insertChampionSkinTask;
-(NIOInsertDataDragonChampionDataTask *)insertDataDragonChampionDataTask;
-(NIOInsertDataDragonRealmTask *)insertDataDragonRealmTask;
-(NIOInsertRealmTask *)insertRealmTask;
-(NIOLoLApiRequestOperationManager *)lolStaticDataApiRequestOperationManager;
-(NIOQueryChampionsTask *)queryChampionsTask;
-(NIOQueryChampionSkinsTask *)queryChampionSkinsTask;
-(NIOQueryRealmsTask *)queryRealmsTask;
@end