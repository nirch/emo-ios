//
//  EMBackend.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMBackend"

#import "EMBackend.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMAppCFGParser.h"
#import "EMPackagesParser.h"

#import "HMServer.h"
#import "HMServer+Packages.h"
#import "EMNotificationCenter.h"

#import <zipzap.h>

@interface EMBackend()

@property (nonatomic) NSMutableDictionary *currentlyDownloadingFromURLS;
@property (nonatomic) NSMutableDictionary *requiredResourcesForEmuOID;
@property (nonatomic) AFHTTPSessionManager *session;
@property (nonatomic) NSDate *latestRefresh;

@end

@implementation EMBackend

#pragma mark - Initialization
// A singleton
+(EMBackend *)sharedInstance
{
    static EMBackend *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMBackend alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMBackend *)sh
{
    return [EMBackend sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        _server = [HMServer new];
        self.currentlyDownloadingFromURLS = [NSMutableDictionary new];
        self.requiredResourcesForEmuOID = [NSMutableDictionary new];
        self.session = [AFHTTPSessionManager manager];
        [self initObservers];
    }
    return self;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataRequired:)
                     name:emkDataRequiredPackages
                   object:nil];
    
    // Getting an update from the server with packages data.
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataUpdated:)
                     name:emkDataUpdatedPackages
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataRequiredPackages];
    [nc removeObserver:emkDataUpdatedPackages];
}

#pragma mark - Observers handlers

/**
 *  The user interface notified the backend that it needs the data to be refreshed.
 */
-(void)onPackagesDataRequired:(NSNotification *)notification
{
    // Making sure required paths exist.
    [EMDB ensureRequiredDirectoriesExist];
    
    // Fetching current info from server.
    BOOL shouldRefresh = NO;
    if (self.latestRefresh) {
        NSDate *now = [NSDate date];
        NSTimeInterval timePassedSincePreviousFetch = [now timeIntervalSinceDate:self.latestRefresh];
        if (timePassedSincePreviousFetch > 600) {
            shouldRefresh = YES;
        }
    } else {
        shouldRefresh = YES;
    }
    
    if (shouldRefresh) {
        [self.server refreshPackagesInfo];
    }
    
    // Save it all
    [EMDB.sh save];
}

/**
 *  The data about the packages was updated (or failed to update).
 */
-(void)onPackagesDataUpdated:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // Error on packages data request to web service
        NSDictionary *info = @{@"error":notification.reportedError};
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil userInfo:info];
        return;
    }
    
    // No errors
    self.latestRefresh = [NSDate date];
    
    // Migration from old local packages
    [self handleMigrationIfRequired];
    
    // Refreshed packages data.
    // Iterate packages and download packages zip files.
    for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
        if ([package shouldDownloadZippedPackage]) {
            // Download resources of the package
            [self downloadResourcesForPackage:package];
        } else if ([package shouldUnzipZippedPackage]) {
            // Unzip resources to a directory.
            [self unzipResourcesForPackage:package];
        }
    }
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil];
}


-(void)downloadResourcesForPackage:(Package *)package
{
    NSURL *remoteURL = [package urlForZippedResources];
    NSURL *localURL = [NSURL URLWithString:[package zippedPackageTempPath]];
    NSURLRequest *request = [NSURLRequest requestWithURL:remoteURL];
    NSString *tempFilePath = [SF:@"%@/%@.zip", NSTemporaryDirectory(), package.oid];
    NSURLSessionDownloadTask *downloadTask;
    
    // The download task.
    downloadTask = [self.session downloadTaskWithRequest:request
                                           progress:nil
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                            return [NSURL fileURLWithPath:tempFilePath];
                                        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                            //
                                            // Download completion.
                                            //
                                            HMParams *params = [HMParams new];
                                            [params addKey:AK_EP_REMOTE_URL value:remoteURL.path];
                                            [params addKey:AK_EP_LOCAL_FILE_NAME value:filePath];

                                            if (error) {
                                                HMLOG(TAG, EM_ERR, @"Error while downloading zipped resources file from %@", remoteURL.path);
                                                [params addKey:AK_EP_ERROR value:[error description]];
                                                [HMReporter.sh analyticsEvent:AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_FAILED info:params.dictionary];
                                            } else {
                                                //
                                                // The zipped file was downloaded to a temp file.
                                                //
                                                HMLOG(TAG, EM_DBG, @"Downloaded resources file: %@", filePath);
                                                
                                                //
                                                // Analytics
                                                //
                                                [HMReporter.sh analyticsEvent:AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_SUCCESS info:params.dictionary];

                                                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.path]) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSFileManager *fm = [NSFileManager defaultManager];
                                                        
                                                        
                                                        // Delete file if already exists at destination.
                                                        [fm removeItemAtPath:localURL.path error:nil];
                                                        
                                                        NSError *error;

                                                        // Copy the temp file to expected place.
                                                        [fm copyItemAtPath:filePath.path toPath:localURL.path error:&error];
                                                        
                                                        // Delete temp file.
                                                        if (error == nil)
                                                            [fm removeItemAtPath:filePath.path error:&error];
                                                        
                                                        // Unzip the resources
                                                        [self unzipResourcesForPackage:package];
                                                    });
                                                } else {
                                                    HMLOG(TAG, EM_ERR, @"Error (missing file) while downloading resources file %@", filePath);
                                                }
                                            }
                                        }];
    
    [downloadTask resume];
}

-(void)unzipResourcesForPackage:(Package *)package
{
    NSURL *zipURL = [package localURLForZippedResources];
    if (zipURL == nil) {
        HMLOG(TAG, EM_ERR, @"Failed to find zipped resources for package %@ at %@", package.name, [package zippedPackageTempPath]);
        return;
    }
    NSURL *targetURL = [NSURL URLWithString:[package resourcesPath]];
    
    HMLOG(TAG, EM_VERBOSE, @"Extracting zipped resource files from %@", zipURL);
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger unzippedFilesCount = [self unzipResourcesInZipFileAtURL:zipURL toTargetURL:targetURL];
        if (unzippedFilesCount > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                package.alreadyUnzipped = @YES;
            });
        }
    });
}

-(NSInteger)unzipResourcesInZipFileAtURL:(NSURL *)zipURL toTargetURL:(NSURL *)targetURL
{
    NSInteger unzippedFilesCount = 0;
    [EMDB ensureDirPathExists:targetURL.path];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Extract.
    NSError *error;
    ZZArchive *zip = [ZZArchive archiveWithURL:zipURL error:&error];
    for (ZZArchiveEntry *entry in zip.entries) {
        NSString* targetPath = [targetURL URLByAppendingPathComponent:entry.fileName].path;
        NSError *error;
        NSData *data = [entry newDataWithError:&error];
        BOOL wasWritten = [data writeToFile:targetPath atomically:YES];
        HMLOG(TAG, EM_VERBOSE, @"Extracting file to %@ success:%@", targetPath, @(wasWritten));
        if (wasWritten) {
            unzippedFilesCount++;
        }
    }
    
    // Delete zip files.
    if (unzippedFilesCount > 0) {
        [fm removeItemAtPath:zipURL.path error:nil];
    }
    return unzippedFilesCount;
}

-(void)downloadResourcesForEmu:(Emuticon *)emu info:(NSDictionary *)info
{
    NSString *identifier = emu.emuDef.oid;
    
    // If already downloading resources for emu, skip for now.
    if (self.requiredResourcesForEmuOID[identifier]) {
        return;
    }
    
    EmuticonDef *emuDef = emu.emuDef;
    NSMutableDictionary *requiredResources = [NSMutableDictionary new];
    
    // Front layer
    if (emuDef.sourceFrontLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceFrontLayer])
        requiredResources[emuDef.sourceFrontLayer] = info;
    
    // Back layer
    if (emuDef.sourceBackLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceBackLayer])
        requiredResources[emuDef.sourceBackLayer] = info;
    
    // User mask layer
    if (emuDef.sourceUserLayerMask &&
        [emuDef isMissingResourceNamed:emuDef.sourceUserLayerMask])
        requiredResources[emuDef.sourceUserLayerMask] = info;
    
    // Download the required resources.
    if (requiredResources.count > 0) {
        self.requiredResourcesForEmuOID[identifier] = requiredResources;
        for (NSString *requiredResource in requiredResources) {
            [self downloadResourceNamed:requiredResource
                             forPackage:emuDef.package
                             identifier:identifier];
        }
    }
}


-(void)downloadResourceNamed:(NSString *)resourceName
                  forPackage:(Package *)package
                  identifier:(NSString *)identifier
{
    NSURL *remoteURL = [package urlForResourceNamed:resourceName];
    
    if (self.currentlyDownloadingFromURLS[remoteURL])
        return;

    // Finale destination of the resource in the package's resource path.
    NSString *targetPath = [SF:@"%@/%@", [package resourcesPath], resourceName];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:remoteURL];
    

    NSString *tempFilePath = [SF:@"%@/%@", NSTemporaryDirectory(), resourceName];
    NSURLSessionDownloadTask *downloadTask;
    
    // The download task.
    __weak EMBackend *weakSelf = self;
    downloadTask = [self.session downloadTaskWithRequest:request
                                           progress:nil
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                            return [NSURL fileURLWithPath:tempFilePath];
                                        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                            if (error) {
                                                HMLOG(TAG, EM_ERR, @"Failed downloading resource from: %@", remoteURL.path);
                                            } else {
                                                HMLOG(TAG, EM_ERR, @"Downloaded resource from: %@", remoteURL.path);
                                                
                                                // Copy it to the resources folder of the package
                                                NSFileManager *fm = [NSFileManager defaultManager];
                                                [fm copyItemAtPath:filePath.path toPath:targetPath error:&error];
                                                
                                                // Delete temp file
                                                [fm removeItemAtPath:filePath.path error:&error];
                                            }
                                            [weakSelf.currentlyDownloadingFromURLS removeObjectForKey:remoteURL];
                                            
                                            
                                            
                                            // Remaining required resources.
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSMutableDictionary *requiredResources = weakSelf.requiredResourcesForEmuOID[identifier];
                                                NSDictionary *info = requiredResources[resourceName];
                                                [requiredResources removeObjectForKey:resourceName];
                                                if (requiredResources.count == 0) {
                                                    // Tried to download all required resources.
                                                    [weakSelf.requiredResourcesForEmuOID removeObjectForKey:identifier];
                                                    
                                                    // Post a notification to the UI
                                                    // Indicating that backend tried to download all resources for that emu.
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDownloadedResourcesForEmuticon
                                                                                                        object:nil
                                                                                                      userInfo:info];

                                                }
                                            });
                                        }];
    self.currentlyDownloadingFromURLS[remoteURL] = downloadTask;
    [downloadTask resume];
}


#pragma mark - Data migration
-(void)handleMigrationIfRequired
{
    // Get old love package
    Package *oldPackage = [Package findWithID:@"1" context:EMDB.sh.context];
    if (oldPackage == nil) return;
    NSArray *oldEmuticons = [Emuticon allEmuticonsInPackage:oldPackage];
    if (oldEmuticons.count != 6) return;
    
    // Get new love package.
    Package *newPackage = [Package findWithID:@"54f826de64617400ae140000" context:EMDB.sh.context];
    if (newPackage == nil) return;
    NSArray *newEmuticons = [Emuticon allEmuticonsInPackage:newPackage];
    if (newEmuticons.count == 0) {
        [newPackage createMissingEmuticonObjects];
    }
    
    //
    // Migration
    //
    if (oldPackage.prefferedFootageOID) {
        newPackage.prefferedFootageOID = oldPackage.prefferedFootageOID;
    }
    
    // Iterate emus of old package
    for (Emuticon *oldEmu in [Emuticon allEmuticonsInPackage:oldPackage]) {
        [oldEmu cleanUp];
        NSString *name = oldEmu.emuDef.name;
        HMLOG(TAG, EM_VERBOSE, @"Migrating: %@", name);

        Emuticon *newEmu = [Emuticon findWithName:name
                                          package:newPackage
                                          context:EMDB.sh.context];
        [newEmu cleanUp];
        if (oldEmu.prefferedFootageOID != nil) {
            newEmu.prefferedFootageOID = oldEmu.prefferedFootageOID;
        }
    }
    
    // Delete old package
    [EMDB.sh.context deleteObject:oldPackage];
}

@end
