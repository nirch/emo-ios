//
//  EMDownloadsManager.h
//  emu
//
//  Created by Aviv Wolf on 6/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define emkDLTaskType @"dl task type"
#define emkDLTaskTypeResources @"dl emu resources"
#define emkDLTaskTypeFullRenderResources @"dl emu full render resources"
#define emkDLTaskTypeFootages @"dl footages files"

@class AWSS3TransferManager;

#define MAX_CONCURRENT_DOWNLOADS 6

@interface EMDownloadsManager2 : NSObject

/**
 *  A weak pointer to the AWS transfer manager.
 */
@property (nonatomic, weak) AWSS3TransferManager *transferManager;

/**
 *  The bucket to download resources from.
 */
@property (nonatomic) NSString *bucketName;

#pragma mark - Initialization
+(instancetype)sharedInstance;
+(instancetype)sh;

#pragma mark - Resume/Pause/Clear
-(void)resume;
-(void)pause;
-(void)clear;

#pragma mark - Enqueue download jobs for required resources.
/**
 *  Enqueue a list of resources for download for a given emu.
 *  the resources will be downloaded later according to priority logic.
 *
 *  @param oid      oid of the emu
 *  @param names    names of required resources
 *  @param path     the path to save to the downloaded resources
 *  @param userInfo extra user info for this request
 */
-(void)enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo;

-(void)enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo
                     taskType:(NSString *)taskType;

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities;
-(void)manageQueue;

@end
