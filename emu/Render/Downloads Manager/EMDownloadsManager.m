//
//  EMDownloadsManager.m
//  emu
//
//  Created by Aviv Wolf on 6/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMDownloadsManager"

#define EMAssertIsMainThread() NSAssert([[NSThread currentThread] isMainThread], @"Call only on main thread");
#define EMAssertNotMainThread() NSAssert(![[NSThread currentThread] isMainThread], @"Call only on background thread");

#import "EMDownloadsManager.h"
#import "EMDB.h"
#import <AFNetworking/AFNetworking.h>

@interface EMDownloadsManager()

@property (nonatomic) NSMutableDictionary *waitingForDownloadEmusPool;
@property (nonatomic) NSMutableDictionary *downloadingEmusPool;
@property (nonatomic) NSMutableDictionary *requiredResourcesByEmuDefOID;
@property (nonatomic) NSMutableDictionary *downloadTasksByURL;
@property EMDB *db;
@property (nonatomic) AFHTTPSessionManager *session;

@end

@implementation EMDownloadsManager


-(instancetype)init
{
    self = [super init];
    if (self) {
        [self finalizeInitializations];
    }
    return self;
}


-(instancetype)initWithDB:(EMDB *)db session:(AFHTTPSessionManager *)session
{
    self = [super init];
    if (self) {
        self.db = db;
        self.session = session;
        [self finalizeInitializations];
    }
    return self;
}


-(void)finalizeInitializations
{
    if (self.db == nil) self.db = EMDB.sh;
    if (self.session == nil) self.session = [AFHTTPSessionManager manager];
    [self initData];
}


-(void)initData
{
    self.waitingForDownloadEmusPool = [NSMutableDictionary new];
    self.downloadingEmusPool = [NSMutableDictionary new];
    self.requiredResourcesByEmuDefOID = [NSMutableDictionary new];
    self.downloadTasksByURL = [NSMutableDictionary new];
}

#pragma mark - Main thread only work
-(void)enqueueEmuOIDForDownload:(NSString *)emuOID withInfo:(NSDictionary *)info
{
    EMAssertIsMainThread();
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _enqueueEmuOIDForDownload:emuOID withInfo:info];
    });
}

-(void)_enqueueEmuOIDForDownload:(NSString *)emuOID withInfo:(NSDictionary *)info
{
    EMAssertIsMainThread();
    Emuticon *emu = [Emuticon findWithID:emuOID context:self.db.context];
    if (emu == nil) return;
    HMLOG(TAG, EM_VERBOSE, @"Should DLR for emu:%@", emuOID);
    self.waitingForDownloadEmusPool[emuOID] = info;
    [self manageQueues];
}

-(void)doneWithEmuOID:(NSString *)emuOID
{
    EMAssertIsMainThread();
    [self.downloadingEmusPool removeObjectForKey:emuOID];
    [self manageQueues];
}

/**
 This method accesses EMDB. Call this only on the main thread!
 */
-(void)manageQueues
{
    EMAssertIsMainThread();

    //
    // Manage queue of waiting to download emus.
    //
    if (self.downloadingEmusPool.count < MAX_CONCURRENT_DOWNLOADS && self.waitingForDownloadEmusPool.count>0) {
        [self popEmuFromWaitingToDownloadPoolAndDownloadAllResources];
    }
}
-(void)popEmuFromWaitingToDownloadPoolAndDownloadAllResources
{
    EMAssertIsMainThread();

    // Get the emu
    NSEnumerator *enumerator = [self.waitingForDownloadEmusPool keyEnumerator];
    NSString *emuOID = [enumerator nextObject];
    Emuticon *emu = [Emuticon findWithID:emuOID context:self.db.context];
    
    // Remove the emu from the waiting pool
    NSDictionary *info = self.waitingForDownloadEmusPool[emuOID];
    [self.waitingForDownloadEmusPool removeObjectForKey:emuOID];
    HMLOG(TAG, EM_VERBOSE, @"Emu:%@/%@ will DLR.", emu.emuDef.package.name, emu.emuDef.name);
    
    // Put on downloading pool after adding some info.
    NSMutableDictionary *resInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    resInfo[emkResourcesRemoteURL] = [emu.emuDef.package urlForResources];
    resInfo[emkResourcesLocalPath] = [emu.emuDef.package resourcesPath];
    self.downloadingEmusPool[emu.oid] = resInfo;
    
    // Download!
    [self downloadResourcesForEmuDef:emu.emuDef resInfo:resInfo];
}


//
// Call this only on the main thread.
-(void)downloadResourcesForEmuDef:(EmuticonDef *)emuDef resInfo:(NSMutableDictionary *)resInfo
{
    EMAssertIsMainThread();

    NSMutableDictionary *requiredResources = [NSMutableDictionary new];
    
    // Back layer
    if (emuDef.sourceBackLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceBackLayer])
        requiredResources[emuDef.sourceBackLayer] = resInfo;
    
    // Front layer
    if (emuDef.sourceFrontLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceFrontLayer]) {
        requiredResources[emuDef.sourceFrontLayer] = resInfo;
    }
    
    // User mask layer
    if (emuDef.sourceUserLayerMask &&
        [emuDef isMissingResourceNamed:emuDef.sourceUserLayerMask])
        requiredResources[emuDef.sourceUserLayerMask] = resInfo;
    
    // Download the required resources.
    NSString *emuDefOID = emuDef.oid;
    self.requiredResourcesByEmuDefOID[emuDefOID] = requiredResources;
    if (requiredResources.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _downloadNextRequiredResourceForEmuDefOID:emuDefOID resInfo:resInfo];
        });
    }
}


#pragma mark - background work
//
// Work to be done on the background.
//

// Iterate required resources and download
-(void)_downloadNextRequiredResourceForEmuDefOID:(NSString *)emuDefOID resInfo:(NSDictionary *)resInfo
{
    NSMutableDictionary *requiredResources = self.requiredResourcesByEmuDefOID[emuDefOID];
    if (requiredResources == nil) return;
    
    // If no more required resources for this emu def
    // We are done with this emu def.
    if (requiredResources.count == 0) {
        // Done. Free the worker for downloads of other emus.
        NSString *emuOID = resInfo[emkEmuticonOID];
        [self.requiredResourcesByEmuDefOID removeObjectForKey:emuDefOID];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doneWithEmuOID:emuOID];
        });
        return;
    }
    
    // Download one of the resources.
    NSString *resource = requiredResources.allKeys.lastObject;
    NSString *destPath = resInfo[emkResourcesLocalPath];
    NSURL *resourcesURL = resInfo[emkResourcesRemoteURL];
    NSURL *url = [resourcesURL URLByAppendingPathComponent:resource];
    NSDictionary *info = requiredResources[resource];
    [self _downloadResourceNamed:resource remoteURL:url destPath:destPath info:info];
}

-(void)_downloadResourceNamed:(NSString *)name
                    remoteURL:(NSURL *)remoteURL
                     destPath:(NSString *)destPath
                         info:(NSDictionary *)info
{
    NSURLRequest *request = [NSURLRequest requestWithURL:remoteURL];
    NSString *tempFilePath = [SF:@"%@/%@.tempdownload", NSTemporaryDirectory(), name];
    HMLOG(TAG, EM_DBG, @"DLR from url: %@", [remoteURL description]);

    // The download task.
    __weak EMDownloadsManager *weakSelf = self;
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request
                                                progress:nil
                                             destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                 NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
                                                 return tempFileURL;
                                             } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                 if (error) {
                                                     HMLOG(TAG, EM_ERR, @"Failed DLR: %@", [error localizedDescription]);
                                                     return;
                                                 }
                                                 
                                                 // Copy downloaded respource to destination path.
                                                 // And download next resource for emu.
                                                 [weakSelf _downloadedResourceNamed:name
                                                                      remoteURL:remoteURL
                                                                       fileURL:filePath
                                                                       destPath:destPath
                                                                           info:info];
                                             }];
    self.downloadTasksByURL[remoteURL] = downloadTask;
    [downloadTask resume];
}


-(void)_downloadedResourceNamed:(NSString *)name
                      remoteURL:(NSURL *)remoteURL
                       fileURL:(NSURL *)fileURL
                       destPath:(NSString *)destPath
                           info:(NSDictionary *)info
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (![fm fileExistsAtPath:destPath isDirectory:nil]) {
        [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            HMLOG(TAG, EM_ERR, @"DLR but failed to create dir %@. %@", destPath, [error localizedDescription]);
        }
    }
    
    NSString *destFilePath = [destPath stringByAppendingPathComponent:name];
    [fm removeItemAtPath:destFilePath error:nil];
    [fm moveItemAtPath:fileURL.path toPath:destFilePath error:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"DLR but failed to copy to %@. %@", destPath, [error localizedDescription]);
        return;
    }
    HMLOG(TAG, EM_DBG, @"DLR success! %@ ==> %@", name, destFilePath);
    
    // Mark that resource downloaded
    NSString *emuDefOID = info[emkEmuticonDefOID];
    NSMutableDictionary *requiredResources = self.requiredResourcesByEmuDefOID[emuDefOID];
    [requiredResources removeObjectForKey:name];

    // Download next resource for this emu def
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _downloadNextRequiredResourceForEmuDefOID:emuDefOID resInfo:info];
    });
}



@end
