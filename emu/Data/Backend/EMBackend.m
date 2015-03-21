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
    [self.server refreshPackagesInfo];
    
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
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    NSString *tempFilePath = [SF:@"%@/%@.zip", NSTemporaryDirectory(), package.oid];
    NSURLSessionDownloadTask *downloadTask;
    
    // The download task.
    downloadTask = [session downloadTaskWithRequest:request
                                           progress:nil
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                            return [NSURL fileURLWithPath:tempFilePath];
                                        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                            //
                                            // Download completion.
                                            //
                                            if (error) {
                                                HMLOG(TAG, EM_ERR, @"Error while downloading resources file %@", filePath);
                                            } else {
                                                //
                                                // The zipped file was downloaded to a temp file.
                                                //
                                                HMLOG(TAG, EM_DBG, @"Downloaded resources file: %@", filePath);
                                                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.path]) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSFileManager *fm = [NSFileManager defaultManager];
                                                        
                                                        // Delete file if already exists at destination.
                                                        [fm removeItemAtPath:localURL.path error:nil];
                                                        
                                                        // Copy the temp file to expected place.
                                                        [fm copyItemAtPath:filePath.path toPath:localURL.path error:nil];
                                                        
                                                        // Delete temp file.
                                                        [fm removeItemAtPath:filePath.path error:nil];
                                                        
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

@end
