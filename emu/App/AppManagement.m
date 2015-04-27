//
//  AppManagement
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppManagement.h"
#import "EMDB.h"

@interface AppManagement()

/*
 Build:
 
 with .d suffix - considered a test application and a dev application.
 with .t suffix - considered a test application.
 without suffix - considered a production application.
 
 */
@property (nonatomic) BOOL isBuildOfTestApplication;
@property (nonatomic) BOOL isBuildOfDevelopmentApplication;


@end

@implementation AppManagement

@synthesize ioQueue = _ioQueue;


#pragma mark - Initialization
// A singleton
+(AppManagement *)sharedInstance
{
    static AppManagement *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppManagement alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(AppManagement *)sh
{
    return [AppManagement sharedInstance];
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

-(BOOL)userSampledByServer
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSDictionary *info = appCFG.uploadUserContent;
    if (info == nil || info[@"enabled"] == nil) return NO;
    return [info[@"enabled"] boolValue];
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


#pragma mark - Queues
-(dispatch_queue_t)ioQueue
{
    if (_ioQueue) return _ioQueue;
    _ioQueue = dispatch_queue_create("io Queue", DISPATCH_QUEUE_SERIAL);
    return _ioQueue;
}

@end
