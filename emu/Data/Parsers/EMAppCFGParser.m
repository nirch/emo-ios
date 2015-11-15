//
//  EMAppCFGParser.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMAppCFGParser"

#import "EMAppCFGParser.h"
#import "EMDB.h"
#import "HMPanel.h"
#import "AppManagement.h"

@implementation EMAppCFGParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    if (info == nil) return;
    
    // Find or create the object
    AppCFG *appCFG = [AppCFG cfgInContext:self.ctx];
    
    // Parse the application configuration
    appCFG.defaultOutputVideoMaxFps = [info safeNumberForKey:@"default_output_video_max_fps"];
    appCFG.onboardingUsingPackage = [info safeOIDStringForKey:@"onboarding_using_package"];
    appCFG.baseResourceURL = [info safeStringForKey:@"base_resource_url"];
    appCFG.bucketName = [info safeStringForKey:@"bucket_name"];
    appCFG.clientName = [info safeStringForKey:@"client_name"];
    appCFG.configUpdatedOn = [self parseDateOfString:[info safeStringForKey:@"config_updated_on"]];
    appCFG.dataVersionForcedFetch = [info safeNumberForKey:@"data_version"];
    
    //
    // Localization
    //
    NSDictionary *localization = [info safeDictionaryForKey:@"localization" defaultValue:nil];
    if ([localization isKindOfClass:[NSDictionary class]]) {
        appCFG.localization = localization;
    } else {
        appCFG.localization = nil;
    }
    
    //
    // Uploading sampled user content
    //
    NSDictionary *uploadUserContent = [info safeDictionaryForKey:@"upload_user_content" defaultValue:@{@"enabled":@NO}];
    if (!(uploadUserContent[@"unchanged"] && [uploadUserContent[@"unchanged"] boolValue])) {
        // unchanged != YES so we need to change to the new values.
        appCFG.uploadUserContent = [info safeDictionaryForKey:@"upload_user_content" defaultValue:@{@"enabled":@NO}];
    }
    
    
    //
    // Application tweaks
    //
    NSDictionary *tweakedValues = info[@"tweaks"];
    if ([tweakedValues isKindOfClass:[NSDictionary class]]) {
        appCFG.tweaks = tweakedValues;
    }
    
    
    //
    // Mixed screen
    //
    NSDictionary *mixedScreenInfo = info[@"mixed_screen"];
    if (mixedScreenInfo == nil) {
        // No info received from server. Use info stored locally.
        mixedScreenInfo = [self localMixedScreenInfo];
    }
    if (mixedScreenInfo) {
        appCFG.mixedScreenEnabled = [mixedScreenInfo safeBoolNumberForKey:@"enabled"];
        appCFG.mixedScreenEmus = [mixedScreenInfo safeArrayOfIdsForKey:@"emus"];
        appCFG.mixedScreenPrioritizedEmus = [mixedScreenInfo safeArrayOfIdsForKey:@"prioritized_emus"];
    } else {
        appCFG.mixedScreenEnabled = @NO;
        appCFG.mixedScreenEmus = nil;
        appCFG.mixedScreenPrioritizedEmus = nil;
    }
    
    //
    // Misc. App Settings
    //
    if (appCFG.playUISounds == nil) appCFG.playUISounds = @YES;
    
    HMLOG(TAG, EM_DBG, @"App cfg parsed:%@", [appCFG description]);
    REMOTE_LOG(@"Parsed app cfg:%@", [appCFG description]);
}


-(NSDictionary *)localMixedScreenInfo
{
    NSString *localInfoFile = AppManagement.sh.isTestApp? @"mixed_screen_test":@"mixed_screen_prod";
    NSString *path = [[NSBundle mainBundle] pathForResource:localInfoFile ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error || json==nil) {
        REMOTE_LOG(@"Failed parsing mixed screen json %@", error);
        HMLOG(TAG, EM_DBG, @"Failed parsing mixed screen json %@", error);
        return nil;
    }
    return json;
}

@end
