//
//  AppInfo.m
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppInfo.h"

@interface AppInfo()

/*
 Build:
 
 with .d suffix - considered a test application and a dev application.
 with .t suffix - considered a test application.
 without suffix - considered a production application.
 
 */
@property (nonatomic) BOOL isBuildOfTestApplication;
@property (nonatomic) BOOL isBuildOfDevelopmentApplication;


@end

@implementation AppInfo

#pragma mark - Initialization
// A singleton
+(AppInfo *)sharedInstance
{
    static AppInfo *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppInfo alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(AppInfo *)sh
{
    return [AppInfo sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        // Build version string
        [self initBuildInfo];
    }
    return self;
}

#pragma mark - Info
-(BOOL)isTestApp
{
    return self.isBuildOfTestApplication;
}

-(BOOL)isDevApp
{
    return self.isBuildOfDevelopmentApplication;
}

-(void)initBuildInfo
{
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.applicationBuild = [[self trimmedString:build] uppercaseString];
    self.isBuildOfTestApplication = [self.applicationBuild hasSuffix:@"T"] || [self.applicationBuild hasSuffix:@"D"];
    self.isBuildOfDevelopmentApplication = [self.applicationBuild hasSuffix:@"D"];
}

-(NSString *)trimmedString:(NSString *)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}



@end
