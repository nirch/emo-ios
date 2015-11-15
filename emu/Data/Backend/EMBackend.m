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
#import "EMDownloadsManager2.h"
#import "EMBackend+AppStore.h"

#import <AWSS3.h>

@interface EMBackend()

@property (nonatomic) NSMutableDictionary *currentlyDownloadingFromURLS;
@property (nonatomic) NSMutableDictionary *requiredResourcesForEmuOID;
@property (nonatomic) AFHTTPSessionManager *session;
@property (nonatomic) AFHTTPSessionManager *backgroundSession;
@property (nonatomic) NSDate *latestRefresh;

@end

@implementation EMBackend

@synthesize transferManager = _transferManager;
@synthesize productsByPID = _productsByPID;
@synthesize productsRequest = _productsRequest;

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
        [self initDownloadManager];
        [self initObservers];
        [self initLocalData];
    }
    return self;
}

-(void)initTransferManager
{
    if (_transferManager == nil) {
        [self transferManager];
    }
}

-(void)initDownloadManager
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    EMDownloadsManager2.sh.transferManager = self.transferManager;
    
    NSString *bucketName = appCFG.bucketName;
    if (bucketName == nil) bucketName = AppManagement.sh.isTestApp?@"homage-emu-test":@"homage-emu-prod";
    EMDownloadsManager2.sh.bucketName = bucketName;
}

-(AWSS3TransferManager *)transferManager
{
    if (_transferManager) return _transferManager;
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:S3_UPLOAD_ACCESS_KEY secretKey:S3_UPLOAD_SECRET_KEY];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    _transferManager = [AWSS3TransferManager defaultS3TransferManager];
    HMLOG(TAG, EM_DBG, @"Started s3 transfer manager");
    return _transferManager;
}


#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // --------------------
    // Packages updates
    
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

    
    // ---------------------------
    // Unhiding packages requests
    //

    // On unhide packages reqest to server required.
    [nc addUniqueObserver:self
                 selector:@selector(onUnhidePackagesRequestRequired:)
                     name:emkDataRequiredUnhidePackages
                   object:nil];
    
    // ---------------------------
    // Request to open a package
    //
    
    [nc addUniqueObserver:self
                 selector:@selector(onOpenPackageRequest:)
                     name:emkDataRequestToOpenPackage
                   object:nil];
    
    
    // --------------------
    // Rendering notifications
    //
    
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
    [nc removeObserver:emkDataRequiredUnhidePackages];
    [nc removeObserver:emkDataRequestToOpenPackage];
    [nc removeObserver:hmkRenderingFinished];
}

#pragma mark - Observers handlers
-(void)onRenderedEmu:(NSNotification *)notification
{
    // Deprecated
    return;
}

/**
 *  The user interface notified the backend that it needs the data to be refreshed.
 */
-(void)onPackagesDataRequired:(NSNotification *)notification
{
    // Making sure required paths exist.
    [EMDB ensureRequiredDirectoriesExist];

    NSDictionary *info = notification.userInfo;
    
    // Used on test app. Debug option to delete all and clean.
    if ([info[@"delete all and clean"] isEqualToNumber:@YES]) {
        [self.server fetchPackagesFullInfoWithInfo:notification.userInfo];
        [EMDB.sh save];
        return;
    }
    
    // In some cases, the app will want to force an update request
    // disregarding when the previous request happened.
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
        if (timePassedSincePreviousFetch > 500) {
            shouldRefresh = YES;
        }
    } else {
        shouldRefresh = YES;
    }
    
    //
    
    if (shouldRefresh) {
        // Refetch all or just get an update?
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        [self.server fetchPackagesUpdatesSince:appCFG.lastUpdateTimestamp withInfo:notification.userInfo];
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

    // Check for error.
    if (notification.isReportingError) {
        // Error on packages data request to web service
        info[@"error"] = notification.reportedError;
    } else {
        self.latestRefresh = [NSDate date];
    }
    
    [AppManagement.sh updateLocalizedStrings];
    
    // One time migration, deprecated footage per package.
    // (reset such emus to default footage)
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (appCFG.deprecatedFootageForPack.boolValue == NO) {
        for (Package *pack in [Package allPackagesInContext:EMDB.sh.context]) {
            pack.prefferedFootageOID = nil;
        }
        appCFG.deprecatedFootageForPack = @YES;
        [EMDB.sh save];
    }
    
    // Premium content updates
    [self storeRefreshProductsInfo];
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil userInfo:info];
}

-(void)onUnhidePackagesRequestRequired:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *code = info[@"code"];
    [self.server unhideUsingCode:code withInfo:info];
}

-(void)onOpenPackageRequest:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info[emkPackageOID] == nil) return;
    
    // First check if pack already exists locally on the device.
    Package *package = [Package findWithID:info[emkPackageOID] context:EMDB.sh.context];
    BOOL packAlreadyOnDevice = package != nil;
    // Tell backend that data update is required.
    // Also pass info about the pack the app needs to navigate to
    // after it gets the required data of the pack.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                        object:self
                                                      userInfo:@{
                                                                 @"forced_reload":@YES,
                                                                 emkDataAlreadyExists:@(packAlreadyOnDevice),
                                                                 emkPackageOID:info[emkPackageOID],
                                                                 @"autoNavigateToPack":@YES
                                                                 }];
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
