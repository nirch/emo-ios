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

@interface AppDelegate ()

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
    [HMReporter.sh analyticsEvent:akApplicationLaunched];
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
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    REMOTE_LOG(@"App lifecycle: %s", __PRETTY_FUNCTION__);
    [EMDB.sh save];
}


@end
