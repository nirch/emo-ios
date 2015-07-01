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
#import "AppManagement.h"

#import "HMServer.h"
#import "HMServer+Packages.h"

#import "HMParams.h"
#import "HMPanel.h"
#import "EMNotificationCenter.h"

#import <zipzap.h>
#import <AWSS3.h>

// S3 credentials (upload only)
#define S3_ACCESS_KEY @"AKIAINLSJGFQCJUIWV3A"
#define S3_SECRET_KEY @"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"


@interface EMBackend()

@property (nonatomic) NSMutableDictionary *currentlyDownloadingFromURLS;
@property (nonatomic) NSMutableDictionary *requiredResourcesForEmuOID;
@property (nonatomic) AFHTTPSessionManager *session;
@property (nonatomic) AFHTTPSessionManager *backgroundSession;
@property (nonatomic) NSDate *latestRefresh;

@property (nonatomic) AWSS3TransferManager *transferManager;

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
        [self initTransferManager];
        [self initObservers];
        [self initLocalData];
    }
    return self;
}

-(void)initTransferManager
{
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:S3_ACCESS_KEY secretKey:S3_SECRET_KEY];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    self.transferManager = [AWSS3TransferManager defaultS3TransferManager];
    HMLOG(TAG, EM_DBG, @"Started s3 transfer manager");
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
    
    // Notifications about newly rendered content
    [nc addUniqueObserver:self
                 selector:@selector(onRenderedEmu:)
                     name:hmkRenderingFinished
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataRequiredPackages];
    [nc removeObserver:emkDataUpdatedPackages];
}

#pragma mark - Observers handlers
-(void)onRenderedEmu:(NSNotification *)notification
{
    // TODO: finish sampled results upload implementation

    // Upload samples only if enabled.
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (![appCFG shouldUploadSampledResults]) return;
    
    // Get related package to sample.
    NSDictionary *info = notification.userInfo;
    NSString *packageOID = info[@"packageOID"];
    NSString *emuOID = info[@"emuticonOID"];
    if (packageOID == nil || emuOID == nil) return;
    
    // Check if package needs to be sampled.
    Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
    if (![package resultNeedToBeSampledForEmuOID:emuOID]) return;
    
    // Get the sampled emu in this package.
    Emuticon *emuToSample = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    if (emuToSample == nil) return;
    
    // Upload the animated gif generated for this emu.
    // Increase the uploaded samples count by 1.
    // Mark package as "already sampled" if max number of samples reached.
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = appCFG.bucketName;

    NSString *key = [emuToSample s3KeyForSampledResult];
    uploadRequest.key = key;
    
    NSURL *localURL = [emuToSample animatedGifURL];
    uploadRequest.body = localURL;
    
    uploadRequest.contentType = @"image/gif";
    uploadRequest.metadata = [emuToSample s3MetaDataForSampledResult];
    
    BFTask *uploadTask = [self.transferManager upload:uploadRequest];
    [uploadTask continueWithExecutor:[BFExecutor defaultExecutor] withBlock:^id(BFTask *task) {
        HMLOG(TAG, EM_DBG, @"upload task: %@", task);
        if (task.completed && task.error == nil) {
            NSInteger count = emuToSample.emuDef.package.sampledEmuCount.integerValue;
            count++;
            emuToSample.emuDef.package.sampledEmuCount = @(count);
            emuToSample.renderedSampleUploaded = @YES;
        }
        
        if (task.error) {
            HMLOG(TAG, EM_DBG, @"Error while uploading sampled result.");
        }
        return nil;
    }];
    

    
//    [[self.transferManager upload:uploadRequest] continueWithSuccessBlock:^id(BFTask *task) {
//        NSInteger count = emuToSample.emuDef.package.sampledEmuCount.integerValue;
//        count++;
//        emuToSample.emuDef.package.sampledEmuCount = @(count);
//        emuToSample.renderedSampleUploaded = @YES;
//        return nil;
//    }];
}

/**
 *  The user interface notified the backend that it needs the data to be refreshed.
 */
-(void)onPackagesDataRequired:(NSNotification *)notification
{
    // Making sure required paths exist.
    [EMDB ensureRequiredDirectoriesExist];

    NSDictionary *info = notification.userInfo;
    BOOL shouldForceRefresh = NO;
    if (info) {
        if ([info[@"forced_reload"] isEqualToNumber:@YES]) {
            shouldForceRefresh = YES;
        }
    }
    
    // Fetching current info from server.
    BOOL shouldRefresh = NO;
    if (self.latestRefresh && !shouldForceRefresh) {
        NSDate *now = [NSDate date];
        NSTimeInterval timePassedSincePreviousFetch = [now timeIntervalSinceDate:self.latestRefresh];
        if (timePassedSincePreviousFetch > 600) {
            shouldRefresh = YES;
        }
    } else {
        shouldRefresh = YES;
    }
    
    //
    
    if (shouldRefresh) {
        [self.server refreshPackagesInfoWithInfo:notification.userInfo];
    }
    
    // Save it all
    [EMDB.sh save];
}


/**
 *  The data about the packages was updated (or failed to update).
 */
-(void)onPackagesDataUpdated:(NSNotification *)notification
{
    NSMutableDictionary *info;
    if (notification.userInfo) {
        info = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    } else {
        info = [NSMutableDictionary new];
    }
    
    if (notification.isReportingError) {
        // Error on packages data request to web service
        info[@"error"] = notification.reportedError;
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil userInfo:info];
        return;
    }
    
    // No errors
    self.latestRefresh = [NSDate date];
    
    // Migration from old local packages
    [self handleMigrationIfRequired];
    
    // Refreshed packages data.
    // Iterate packages and download packages zip files.
    for (Package *package in [Package allPackagesPrioritizedInContext:EMDB.sh.context]) {
        if ([package shouldDownloadZippedPackage]) {
            // Download resources of the package (but only if marked for auto download)
            if (package.shouldAutoDownload) [self downloadZippedResourcesForPackage:package];
        } else if ([package shouldUnzipZippedPackage]) {
            // Unzip resources to a directory.
            [self unzipResourcesForPackage:package];
        }
    }
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil userInfo:info];
}

-(void)downloadZippedResourcesForPackage:(Package *)package
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
                                                     [HMPanel.sh analyticsEvent:AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_FAILED info:params.dictionary];
                                                 } else {
                                                     //
                                                     // The zipped file was downloaded to a temp file.
                                                     //
                                                     HMLOG(TAG, EM_DBG, @"Downloaded resources file: %@", filePath);
                                                     
                                                     //
                                                     // Analytics
                                                     //
                                                     [HMPanel.sh analyticsEvent:AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_SUCCESS info:params.dictionary];
                                                     if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.path]) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSFileManager *fm = [NSFileManager defaultManager];
                                                             [fm removeItemAtPath:localURL.path error:nil];
                                                             NSError *error;
                                                             [fm copyItemAtPath:filePath.path toPath:localURL.path error:&error];
                                                             if (error == nil) [fm removeItemAtPath:filePath.path error:&error];
                                                             [self unzipResourcesForPackage:package];
                                                         });
                                                     } else {
                                                         HMLOG(TAG, EM_ERR, @"Error (missing file) while downloading resources file %@", filePath);
                                                     }
                                                 }
                                             }];
    [downloadTask resume];
}

-(void)bgDownloadZippedResourcesForPackage:(Package *)package
                       completionHandler:(void (^)())completionHandler
                             failHandler:(void (^)())failHandler
{
    NSURL *remoteURL = [package urlForZippedResources];
    NSURL *localURL = [NSURL URLWithString:[package zippedPackageTempPath]];
    NSURLRequest *request = [NSURLRequest requestWithURL:remoteURL];
    NSString *tempFilePath = [SF:@"%@/%@.zip", NSTemporaryDirectory(), package.oid];
    NSURLSessionDownloadTask *downloadTask;
    if (self.backgroundSession == nil) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"background downloads"];
        self.backgroundSession = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    }
    
    downloadTask = [self.backgroundSession downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:tempFilePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error) {failHandler();return;}
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.path]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fm = [NSFileManager defaultManager];
                [fm removeItemAtPath:localURL.path error:nil];

                NSError *error;
                [fm copyItemAtPath:filePath.path toPath:localURL.path error:&error];
                if (error) {failHandler();return;}
                
                [fm removeItemAtPath:filePath.path error:&error];
                if (error) {failHandler();return;}
                
                [self bgUnzipResourcesSyncForPackage:package];
                completionHandler();
            });
        } else {
            failHandler();
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

-(void)bgUnzipResourcesSyncForPackage:(Package *)package
{
    NSURL *zipURL = [package localURLForZippedResources];
    if (zipURL == nil) return;
    NSURL *targetURL = [NSURL URLWithString:[package resourcesPath]];
    [self unzipResourcesInZipFileAtURL:zipURL toTargetURL:targetURL];
    package.alreadyUnzipped = @YES;
    [EMDB.sh save];
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

-(void)downloadResourcesForEmuDef:(EmuticonDef *)emuDef info:(NSDictionary *)info
{
    NSString *identifier = emuDef.oid;

    // If already downloading resources for emu, skip for now.
    if (self.requiredResourcesForEmuOID[identifier]) {
        return;
    }
    
    NSMutableDictionary *requiredResources = [NSMutableDictionary new];
    
    // Front layer
    if (emuDef.sourceFrontLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceFrontLayer])
        requiredResources[emuDef.sourceFrontLayer] = info;
    
    // Back layer
    if (emuDef.sourceBackLayer &&
        [emuDef isMissingResourceNamed:emuDef.sourceBackLayer])
        requiredResources[emuDef.sourceBackLayer] = info;
    
    // User layer - static mask
    if (emuDef.sourceUserLayerMask &&
        [emuDef isMissingResourceNamed:emuDef.sourceUserLayerMask])
        requiredResources[emuDef.sourceUserLayerMask] = info;
    
    // User layer - dynamic mask
    if (emuDef.sourceUserLayerDynamicMask &&
        [emuDef isMissingResourceNamed:emuDef.sourceUserLayerDynamicMask])
        requiredResources[emuDef.sourceUserLayerDynamicMask] = info;
    
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

-(void)downloadResourcesForEmu:(Emuticon *)emu info:(NSDictionary *)info
{
    [self downloadResourcesForEmuDef:emu.emuDef info:info];
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


#pragma mark - Background fetch
-(void)reloadPackagesInTheBackgroundWithNewDataHandler:(void (^)())newDataHandler
                                      noNewDataHandler:(void (^)())noNewDataHandler
                                    failedFetchHandler:(void (^)())failedFetchHandler
{
    NSString *relativeURL = @"emuapi/packages/full";
    HMLOG(TAG, EM_DBG, @"GET request:%@/%@", self.server.session.baseURL, relativeURL);
 
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    [self.server.session GET:relativeURL
                  parameters:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {

                         //
                         // Successful response from server.
                         //

                         //
                         // Parse response.
                         //
                         parser.objectToParse = responseObject;
                         [parser parse];

                         //
                         // Parse error.
                         //
                         if (parser.error) {
                             //
                             // Parser error.
                             //
                             HMLOG(TAG, EM_DBG, @"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                             failedFetchHandler();
                             return;
                         }

                         //
                         // Parse successful
                         //
                         Package *newlyAvailablePackage = [Package newlyAvailablePackageInContext:EMDB.sh.context];
                         if (newlyAvailablePackage) {
                             newDataHandler();
                         } else {
                             noNewDataHandler();
                         }

                     } failure:^(NSURLSessionDataTask *task, NSError *error) {
                         failedFetchHandler();
                     }];
    
}


-(void)notifyUserAboutUpdateForPackage:(Package *)package
{
    NSString *alertBody;
    if (package.notificationText) {
        alertBody = package.notificationText;
    } else {
        alertBody = [SF:LS(@"GENERAL_NEW_CONTENT_MESSAGE"), [package localizedLabel]];
    }

    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (settings.types & UIUserNotificationTypeAlert) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
        localNotification.alertBody = alertBody;
        localNotification.timeZone = [NSTimeZone defaultTimeZone];

        // Badge
        if (settings.types & UIUserNotificationTypeBadge) {
            localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
        }
        
        // Add info to the notification
        localNotification.userInfo = @{@"packageOID":package.oid};
        
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

#pragma mark - Local data
-(void)initLocalData
{
    // Ensure critical data is available, and if not, use data bundled with the app.
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (appCFG.mixedScreenEmus == nil) {
        [self initMixedScreenData];
    }
}

-(void)initMixedScreenData
{
    // The onboarding local file name for tests and production.
    NSString *onboardingLocalFileName = AppManagement.sh.isTestApp? @"onboarding_packages_test":@"onboarding_packages_prod";
    NSString *path = [[NSBundle mainBundle] pathForResource:onboardingLocalFileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    parser.parseForOnboarding = YES;
    parser.objectToParse = json;
    [parser parse];
    
    // Create missing emus
    for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
        [package createMissingEmuticonObjects];
    }
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil];
}


@end
