//
//  AppInfo.h
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppInfo : NSObject

#pragma mark - Initialization
+(AppInfo *)sharedInstance;
+(AppInfo *)sh;

#pragma mark - App information

// Application build
@property (nonatomic) NSString *applicationBuild;

// Is a test application? (app with the .t or .d build string suffix)
-(BOOL)isTestApp;

// Is it a dev applications? (app with the .d build string suffix)
-(BOOL)isDevApp;

@end
