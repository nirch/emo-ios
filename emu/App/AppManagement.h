//
//  AppManagement
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define LSS(STRINGKEY, DEFSTRING) [AppManagement.sh serverSideLocalizedString:STRINGKEY defaultValue:DEFSTRING]
#define RESOURCES_SCALE_STRING AppManagement.sh.resourcesScaleString
#import <Foundation/Foundation.h>

@interface AppManagement : NSObject

#pragma mark - Initialization
+(AppManagement *)sharedInstance;
+(AppManagement *)sh;

#pragma mark - App information

// Application build
@property (nonatomic) NSString *applicationBuild;

// Is a test application? (app with the .t or .d build string suffix)
-(BOOL)isTestApp;

// Is it a dev applications? (app with the .d build string suffix)
-(BOOL)isDevApp;

// Is this user's results are (were) sampled by the server?
-(BOOL)userSampledByServer;

#pragma mark - HSDK
-(NSString *)hsdkVersionString;

#pragma mark - device specific info
+(NSString *)deviceModelName;
+(NSNumber *)deviceGeneration;
@property (nonatomic, readonly) NSString *resourcesScaleString;

#pragma mark - Localization
@property (nonatomic, readonly) NSString *prefferedLanguages;
-(NSString *)serverSideLocalizedString:(NSString *)stringKey defaultValue:(NSString *)defaultValue;
-(void)updateLocalizedStrings;

#pragma mark - Queues
@property (nonatomic, readonly) dispatch_queue_t ioQueue;

@end
