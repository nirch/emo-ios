//
//  EMPackahesParser.m
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMPackagesParser"

#import "EMPackagesParser.h"
#import "EMDB.h"
#import "EMPackageParser.h"
#import "EMAppCFGParser.h"
#import "NSDictionary+TypeSafeValues.h"


@implementation EMPackagesParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    if (info == nil) return;
    
    //
    // Packages priorities
    //
    NSDictionary *packagesPriorities = [HMParser prioritiesByOID:info[@"prioritized_packages"]];
    
    //
    // Mixed screen priorities
    //
    NSDictionary *mixedScreenPriorities = [HMParser prioritiesByOID:info[@"mixed_screen"][@"prioritized_emus"]];

    //
    // Parse application's configurations
    //
    EMAppCFGParser *cfgParser = [[EMAppCFGParser alloc] initWithContext:self.ctx];
    cfgParser.objectToParse = info;
    [cfgParser parse];
    HMLOG(TAG, EM_DBG, @"Server response:%@", info);
    
    //
    // Iterate and parse packages
    //
    EMPackageParser *packageParser = [[EMPackageParser alloc] initWithContext:self.ctx];
    NSArray *packages = info[@"packages"];
    for (NSDictionary *packageInfo in packages) {
        packageParser.objectToParse = packageInfo;
        packageParser.mixedScreenPriorities = mixedScreenPriorities;
        packageParser.packagesPriorities = packagesPriorities;
        packageParser.parseForOnboarding = self.parseForOnboarding;
        [packageParser parse];
    }
    
    // And we're done.
    HMLOG(TAG, EM_VERBOSE, @"Parsed %@ package/s", @(packages.count));
    [EMDB.sh save];
}

@end
