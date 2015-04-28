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
    
    NSDictionary *uploadUserContent = [info safeDictionaryForKey:@"upload_user_content" defaultValue:@{@"enabled":@NO}];
    if (!(uploadUserContent[@"unchanged"] && [uploadUserContent[@"unchanged"] boolValue])) {
        // unchanged != YES so we need to change to the new values.
        appCFG.uploadUserContent = [info safeDictionaryForKey:@"upload_user_content" defaultValue:@{@"enabled":@NO}];
    }
    
    
    NSDictionary *tweakedValues = info[@"tweaks"];
    if ([tweakedValues isKindOfClass:[NSDictionary class]]) {
        appCFG.tweaks = tweakedValues;
    }
    
    HMLOG(TAG, EM_DBG, @"App cfg parsed:%@", [appCFG description]);
    REMOTE_LOG(@"Parsed app cfg:%@", [appCFG description]);
}

@end
