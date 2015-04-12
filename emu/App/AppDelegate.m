//
//  AppDelegate.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"AppDelegate"

#import "AppDelegate.h"
#import "EMDB.h"
#import "EMBackend.h"
#import "EMNotificationCenter.h"
#import "EMShareFBMessanger.h"
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "HMServer.h"

@interface AppDelegate ()<
    FBSDKMessengerURLHandlerDelegate
>

@property (nonatomic) FBSDKMessengerURLHandler *messengerUrlHandler;

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
    LoggerSetupBonjour(logger, NULL, (CFStringRef)@"AvivLogger");
}

#pragma mark - App Delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize Logging
    [self initLogging];
    
    // Initialize backend
    [EMBackend sharedInstance];
    
    // Initialize analytics, set super parameters and report application launch.
    [HMReporter.sh initializeAnalyticsWithLaunchOptions:launchOptions];
    [HMReporter.sh reportSuperParameters];
    [HMReporter.sh analyticsEvent:AK_E_APP_LAUNCHED];
    [HMReporter.sh checkAndReportIfAppUpdated];
    
    // FB Messanger optimized integration
    self.messengerUrlHandler = [[FBSDKMessengerURLHandler alloc] init];
    self.messengerUrlHandler.delegate = self;

    // Background fetches interval.
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    // Launched.
    HMLOG(TAG, EM_DBG, @"Application launched");
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    self.fbContext = nil;
    [HMReporter.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [HMReporter.sh analyticsEvent:AK_E_APP_ENTERED_BACKGROUND];
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [HMReporter.sh analyticsEvent:AK_E_APP_ENTERED_FOREGROUND];
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    
    // Logs 'install' and 'app activate' App Events.
    [FBAppEvents activateApp];
    
    // Analytics
    [HMReporter.sh reportCountedSuperParameterForKey:AK_S_DID_BECOME_ACTIVE_COUNT];
    [HMReporter.sh analyticsEvent:AK_E_APP_DID_BECOME_ACTIVE];
    application.applicationIconBadgeNumber = 0;
    
    // If a current fb messanger sharer exists,
    // Notify it that the application launched.
    [self.currentFBMSharer onAppDidBecomeActive];
    
    // Update latest published package
    Package *latestPublishedPackage = [Package latestPublishedPackageInContext:EMDB.sh.context];
    if (latestPublishedPackage == nil) return;
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.latestPackagePublishedOn = latestPublishedPackage.firstPublishedOn;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Check if the handler knows what to do with this url
    if ([_messengerUrlHandler canOpenURL:url sourceApplication:sourceApplication]) {
        // Handle the url
        [_messengerUrlHandler openURL:url sourceApplication:sourceApplication];
    }
    return YES;
}

#pragma mark - FBSDKMessengerURLHandlerDelegate
// Cancel
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleCancelWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context
{
    self.fbContext = nil;
    [self.currentFBMSharer onFBMCancel];
    
    // Analytics
    [HMReporter.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@NO];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"cancel"];
    [HMReporter.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}

// Open
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleOpenFromComposerWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context
{
    self.fbContext = context;
    [self.currentFBMSharer onFBMOpen];
    
    // Analytics
    [HMReporter.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@YES];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"open"];
    [HMReporter.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}

// Reply
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleReplyWithContext:(FBSDKMessengerURLHandlerReplyContext *)context
{
    self.fbContext = context;
    [self.currentFBMSharer onFBMReply];
    
    // If not on first screen, pop back to the main screen (with no animation).
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
        [nc popToRootViewControllerAnimated:NO];
    }
    
    // Analytics
    [HMReporter.sh reportSuperParameterKey:AK_S_IN_MESSANGER_CONTEXT value:@YES];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_LINK_TYPE value:@"reply"];
    [HMReporter.sh analyticsEvent:AK_E_FBM_INTEGRATION info:params.dictionary];
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    HMParams *params = [HMParams new];
    [params addKey:AK_S_NOTIFICATIONS_SETTINGS value:@(notificationSettings.types)];
    [HMReporter.sh reportSuperParameters:params.dictionary];
    [HMReporter.sh analyticsEvent:AK_E_NOTIFICATIONS_REGISTRATION_SETTINGS info:params.dictionary];
}

#pragma mark - Opened notifications
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info == nil) return;
    
    NSString *packageOID = info[@"packageOID"];
    if (packageOID == nil) return;
    
    Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
    if (package == nil) return;
    
    // If not on first screen, pop back to the main screen (with no animation).
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
        [nc popToRootViewControllerAnimated:NO];
        if (nc.presentedViewController) {
            [nc dismissViewControllerAnimated:NO completion:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIMainShouldShowPackage
                                                            object:self
                                                          userInfo:@{@"packageOID":package.oid}];
    }
    
    // Cool. We should preffer this package.
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_OID value:package.oid];
    [params addKey:AK_EP_PACKAGE_NAME value:package.name];
    [HMReporter.sh analyticsEvent:AK_E_NOTIFICATIONS_USER_OPENED_NOTIFICATION info:params.dictionary];
}


#pragma mark - Background fetches
//
// performFetchWithCompletionHandler
// Called by iOS, when it feels like it :-) when the app is in the background.
//
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *msg = [SF:@"Application will try to perform bg fetch %@", [NSDate date]];
    HMLOG(TAG, EM_DBG, @"%@", msg);
    REMOTE_LOG(@"%@", msg);
    
    HMParams *params = [HMParams new];
    [HMReporter.sh initializeAnalyticsWithLaunchOptions:nil];
    
    [EMBackend.sh reloadPackagesInTheBackgroundWithNewDataHandler:^{
        
        Package *newlyAvailablePackage = [Package newlyAvailablePackageInContext:EMDB.sh.context];
        if (newlyAvailablePackage) {
            [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"newData"];
            [params addKey:AK_EP_PACKAGE_OID value:newlyAvailablePackage.oid];
            [params addKey:AK_EP_PACKAGE_NAME value:newlyAvailablePackage.name];
            [HMReporter.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];
            [EMBackend.sh notifyUserAboutUpdateForPackage:newlyAvailablePackage];
        }

    } noNewDataHandler:^{
        
        [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"noNewData"];
        [HMReporter.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];
        
        //
        // Fetch successful, but no new data.
        //
        HMLOG(TAG, EM_DBG, @"BG Fetch: no new data available.");
        REMOTE_LOG(@"Background Fetch: no new data");
        completionHandler(UIBackgroundFetchResultNoData);
        
    } failedFetchHandler:^{

        [params addKey:AK_EP_RESULT_TYPE valueIfNotNil:@"failed"];
        [HMReporter.sh analyticsEvent:AK_E_BE_BACKGROUND_FETCH info:params.dictionary];

        //
        // Fetch failed.
        //
        HMLOG(TAG, EM_DBG, @"BG Fetch: Failed fetch new data in the background.");
        REMOTE_LOG(@"Background Fetch: failed");
        completionHandler(UIBackgroundFetchResultFailed);
        
    }];
}


@end
