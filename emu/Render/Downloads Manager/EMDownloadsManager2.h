//
//  EMDownloadsManager.h
//  emu
//
//  Created by Aviv Wolf on 6/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class AWSS3TransferManager;

#define MAX_CONCURRENT_DOWNLOADS 4

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

#pragma mark - Resume/Pause
-(void)resume;
-(void)pause;

#pragma mark - Enqueue download jobs for required resources.
-(void)enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo;

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities;
-(void)manageQueue;

@end
