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
    
    HMLOG(TAG, EM_DBG, @"Application launched");
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
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
    
    // If a current fb messanger sharer exists,
    // Notify it that the application launched.
    [self.currentFBMSharer onAppDidBecomeActive];
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
    self.fbContext = context;
    [self.currentFBMSharer onFBMCancel];
}

// Open
-(void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler didHandleOpenFromComposerWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context
{
    self.fbContext = context;
    [self.currentFBMSharer onFBMOpen];
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
}


@end
