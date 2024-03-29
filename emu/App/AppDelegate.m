//
//  AppDelegate.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import AVFoundation;

#define TAG @"AppDelegate"

#import "mach/mach.h"
#import <objc/message.h>
#import "AppDelegate.h"
#import "EMDB.h"
#import "EMBackend.h"
#import "EMNotificationCenter.h"
#import "EMShareFBMessanger.h"
#import "HMServer.h"
#import "HMServer+User.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import "EMUISound.h"
#import "AppManagement.h"
#import "AppManagement.h"
#import "EMCaches.h"
#import "EMURLSchemeHandler.h"
#import <HomageSDKCore/HomageSDKCore.h>
#import <PINRemoteImage/PINRemoteImageManager.h>

@interface AppDelegate ()<
    FBSDKMessengerURLHandlerDelegate
>

@property (nonatomic) FBSDKMessengerURLHandler *messengerUrlHandler;
@property (nonatomic) EMURLSchemeHandler *emuURLHandler;

//@property (nonnull) NSTimer *debugT;

@end

@implementation AppDelegate

-(void)initLogging
{
    Logger *logger = LoggerGetDefaultLogger();
    LoggerSetOptions(logger,
                     kLoggerOption_CaptureSystemConsole |
                     kLoggerOption_LogToConsole |
                     kLoggerOption_BufferLogsUntilConnection |
                     kLoggerOption_BrowseBonjour |
                     kLoggerOption_BrowseOnlyLocalDomain |
                     kLoggerOption_UseSSL
                     );
    NSString *deviceName = [[UIDevice currentDevice] name];
    if ([deviceName isEqualToString:@"iPhone Simulator"]) deviceName = @"Aviv's iPhone 6 Plus";
    LoggerSetupBonjour(logger, NULL, (CFStringRef)CFBridgingRetain(deviceName));
}

#pragma mark - App Delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize rendering tracking
    sdkENV sdkEnvironment = [AppManagement.sh isDevApp] || [AppManagement.sh isTestApp] ? sdkEnvDev : sdkEnvProduction;
    [HSDKCore.sh useInEnvironment:sdkEnvironment];
    
    // Initialize Logging
    [self initLogging];
    
    // Initialize backend
    [EMBackend sharedInstance];
    
    // Crash reports
    [HMPanel.sh initCrashReports];
    
    // Initialize analytics, set super parameters and report application launch.
    [HMPanel.sh initializeAnalyticsWithLaunchOptions:launchOptions];
    [HMPanel.sh reportBuildInfo];
    [HMPanel.sh reportSuperParameters];
    [HMPanel.sh checkAndReportIfAppUpdated];
    [HMPanel.sh analyticsEvent:AK_E_APP_LAUNCHED];
    [HMPanel.sh personIdentify];
    [HMPanel.sh reportPersonDetails];
    
    // Experiments
    [HMPanel.sh initializeExperimentsWithLaunchOptions:launchOptions];
    
    // FB Messanger optimized integration
    self.messengerUrlHandler = [[FBSDKMessengerURLHandler alloc] init];
    self.messengerUrlHandler.delegate = self;

    // Background fetches interval.
    [application setMinimumBackgroundFetchInterval:[AppCFG tweakedInterval:@"background_fetches_minimum_interval" defaultValue:10800]];

    // Launched.
    HMLOG(TAG, EM_DBG, @"Application launched info:%@", launchOptions);
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    
    // Push notifications
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (appCFG.userAskedInMainScreenAboutAlerts.boolValue) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    
    // User sign in
    [EMBackend.sh.server signInUser];
    
    // Preload sounds
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    [EMUISound sh];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    self.fbContext = nil;
    [HMPanel.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@NO];
    [EMCaches.sh checkCacheStatus];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [HMPanel.sh analyticsEvent:AK_E_APP_ENTERED_BACKGROUND];
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}

-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [HMPanel.sh analyticsEvent:AK_E_APP_ENTERED_FOREGROUND];
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    
    // Migration from V<2.2 to V>=2.2 footage type support
    // (starting V2.2 renders using HCRender with video/gif source instead of png sequence source)
//    [EMBackend.sh footagesMigrationIfRequired];
    
    // Logs 'install' and 'app activate' App Events.
    [FBSDKAppEvents activateApp];
    
    // Analytics
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_DID_BECOME_ACTIVE_COUNT];
    [HMPanel.sh analyticsEvent:AK_E_APP_DID_BECOME_ACTIVE];
    [HMPanel.sh personDetails:@{
                                @"lastAppBecameActiveTime":[[NSDate date] description],
                                @"$name":[[UIDevice currentDevice] name]
                                }];
    application.applicationIconBadgeNumber = 0;
    
    // Report build info to analytics
    [HMPanel.sh reportBuildInfo];
    
    // If a current fb messanger sharer exists,
    // Notify it that the application launched.
    [self.currentFBMSharer onAppDidBecomeActive];
    
    // Update latest published package
    Package *latestPublishedPackage = [Package latestPublishedPackageInContext:EMDB.sh.context];
    if (latestPublishedPackage == nil) return;
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.latestPackagePublishedOn = latestPublishedPackage.firstPublishedOn;
    
    // Notify that app did become active.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkAppDidBecomeActive object:self userInfo:nil];    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    // Emu codes url schemes.
    if ([EMURLSchemeHandler canHandleURL:url]) {
        self.emuURLHandler = [EMURLSchemeHandler new];
        return [self.emuURLHandler application:application
                                       openURL:url
                             sourceApplication:sourceApplication
                                    annotation:annotation];
    }
    
    // Experiments (currently uses optimizely)
    if([HMPanel.sh handleOpenURL:url]) {
        return YES;
    }
    
    // Facebook Messenger URLs
    if ([_messengerUrlHandler canOpenURL:url sourceApplication:sourceApplication]) {
        BOOL didOpenedFBMURL = [_messengerUrlHandler openURL:url sourceApplication:sourceApplication];
        return didOpenedFBMURL;
    }
    return NO;
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    HMLOG(TAG, EM_APP, @"Memory warning captured in App Delegate");
    REMOTE_LOG(@"Memory warning captured in App Delegate");
    [self report_memory];
    [[EMCaches sh] clearMemoryCache];
    [self report_memory];
}

-(void) report_memory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
        REMOTE_LOG(@"Memory in use (in bytes): %lu", (unsigned long)info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
        REMOTE_LOG(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

#pragma mark - FBSDKMessengerURLHandlerDelegate
// Cancel
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleCancelWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context
{
    self.fbContext = nil;
    [self.currentFBMSharer onFBMCancel];
    
    // Analytics
    [HMPanel.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@NO];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"cancel"];
    [HMPanel.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}

// Open
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleOpenFromComposerWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context
{
    self.fbContext = context;
    [self.currentFBMSharer onFBMOpen];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationShouldShowFeed
                                                            object:nil
                                                          userInfo:nil];
    });
    
    // Analytics
    [HMPanel.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@YES];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"open"];
    [HMPanel.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}


// Reply
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleReplyWithContext:(FBSDKMessengerURLHandlerReplyContext *)context
{
    self.fbContext = context;
    [self.currentFBMSharer onFBMReply];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationShouldShowFeed
                                                            object:nil
                                                          userInfo:nil];
    });
    
    // Analytics
    [HMPanel.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@YES];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"reply"];
    [HMPanel.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}

-(BOOL)isInFBMContext
{
    return self.fbContext != nil;
}

#pragma mark - Notifications
-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    HMParams *params = [HMParams new];
    [params addKey:AK_S_NOTIFICATIONS_SETTINGS value:@(notificationSettings.types)];
    [HMPanel.sh reportSuperParameters:params.dictionary];
    [HMPanel.sh analyticsEvent:AK_E_NOTIFICATIONS_REGISTRATION_SETTINGS info:params.dictionary];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    HMLOG(TAG, EM_DBG, @"Failed to register to remote notifications with error:%@", [error localizedDescription]);
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    HMLOG(TAG, EM_DBG, @"Registered to remote notifications with token:%@", [deviceToken description]);

    // Foreward the push token to mixpanel.
    [HMPanel.sh personPushToken:deviceToken];
    
    // Sign in user with the push token
    NSString *pushToken = [deviceToken description];
    if (pushToken) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        appCFG.pushToken = pushToken;
        [EMDB.sh save];
        [EMBackend.sh.server signInUser];
    }
}

#pragma mark - Opened notifications & universal links
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_NOTIFICATION_TYPE value:@"local"];
    [self handleNotificationWithInfo:notification.userInfo params:params];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_NOTIFICATION_TYPE value:@"remote"];
        [self handleNotificationWithInfo:userInfo params:params];
    }
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)info fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    HMLOG(TAG, EM_DBG, @"APN: Background fetch requested");
    if (application.applicationState == UIApplicationStateBackground) {
        [EMBackend.sh reloadPackagesInTheBackgroundWithNewDataHandler:^{
            completionHandler(UIBackgroundFetchResultNewData);
        } noNewDataHandler:^{
            completionHandler(UIBackgroundFetchResultNoData);
        } failedFetchHandler:^{
            completionHandler(UIBackgroundFetchResultFailed);
        }];
    } else if (application.applicationState == UIApplicationStateInactive) {
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_NOTIFICATION_TYPE value:@"remote"];
        [self handleNotificationWithInfo:info params:params];
    }

}

-(void)handleNotificationWithInfo:(NSDictionary *)info params:(HMParams *)params
{
    // Handle package alert notifications
    NSString *packageOID = info[emkPackageOID];
    [params addKey:AK_EP_PACKAGE_OID value:packageOID];
    if (packageOID != nil) {
        Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
        if (package) {
            [params addKey:AK_EP_PACKAGE_NAME value:package.name];
        }
    }
    [params addKey:AK_EP_TEXT valueIfNotNil:info[@"alert"]];
    [HMPanel.sh analyticsEvent:AK_E_NOTIFICATIONS_USER_OPENED_NOTIFICATION info:params.dictionary];
    if (packageOID != nil) {
        [self handleNavigateToPackageOID:packageOID];
    }
}

-(void)handleNavigateToPackageOID:(NSString *)packOID
{
    // Block the UI until finishing the flow of opening the pack
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationShowBlockingProgress
                                                        object:nil
                                                      userInfo:@{@"title":LS(@"PROGRESS_OPENING_PACK_TITLE")}];
    
    
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        HMParams *params = [HMParams new];
        [params addKey:emkPackageOID value:packOID];
        [params addKey:@"autoNavigateToPack" value:@YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequestToOpenPackage
                                                            object:nil
                                                          userInfo:params.dictionary];
    });
}

#pragma mark - Background fetches
//
// performFetchWithCompletionHandler
// Called by iOS, when it feels like it :-) when the app is in the background.
//
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Tweak: allow/disable background fetches.
    BOOL allowBackgroundFetches = [AppCFG tweakedBool:@"allow_background_fetches" defaultValue:NO];
    if (!allowBackgroundFetches) {
        HMLOG(TAG, EM_DBG, @"skipping background fetch.");
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    // Background fetches allowed.
    NSString *msg = [SF:@"Application will try to perform bg fetch %@", [NSDate date]];
    HMLOG(TAG, EM_DBG, @"%@", msg);
    REMOTE_LOG(@"%@", msg);
    
    HMParams *params = [HMParams new];
    [HMPanel.sh initializeAnalyticsWithLaunchOptions:nil];
    [EMBackend.sh reloadPackagesInTheBackgroundWithNewDataHandler:^{
        
        Package *newlyAvailablePackage = [Package newlyAvailablePackageInContext:EMDB.sh.context];
        if (newlyAvailablePackage) {
            [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"newData"];
            [params addKey:AK_EP_PACKAGE_OID value:newlyAvailablePackage.oid];
            [params addKey:AK_EP_PACKAGE_NAME value:newlyAvailablePackage.name];
            [HMPanel.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];
            [EMBackend.sh notifyUserAboutUpdateForPackage:newlyAvailablePackage];
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"noNewData"];
            [HMPanel.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];
            completionHandler(UIBackgroundFetchResultNoData);
        }

    } noNewDataHandler:^{
        
        [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"noNewData"];
        [HMPanel.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];
        
        //
        // Fetch successful, but no new data.
        //
        HMLOG(TAG, EM_DBG, @"BG Fetch: no new data available.");
        REMOTE_LOG(@"Background Fetch: no new data");
        completionHandler(UIBackgroundFetchResultNoData);
        
    } failedFetchHandler:^{

        [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"failed"];
        [HMPanel.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];

        //
        // Fetch failed.
        //
        HMLOG(TAG, EM_DBG, @"BG Fetch: Failed fetch new data in the background.");
        REMOTE_LOG(@"Background Fetch: failed");
        completionHandler(UIBackgroundFetchResultFailed);
        
    }];
}

@end
