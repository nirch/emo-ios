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
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSNumber *latestTimestamp = appCFG.lastUpdateTimestamp?appCFG.lastUpdateTimestamp:[NSNumber numberWithFloat:0];
    
    for (NSDictionary *packageInfo in packages) {
        packageParser.objectToParse = packageInfo;
        packageParser.mixedScreenPriorities = mixedScreenPriorities;
        packageParser.parseForOnboarding = self.parseForOnboarding;
        [packageParser parse];
        
        // last update timestamp
        NSNumber *timestamp = packageInfo[@"data_update_time_stamp"];
        if (![timestamp isKindOfClass:[NSNumber class]]) continue;
        if (timestamp && [latestTimestamp compare:timestamp] == NSOrderedAscending) {
            latestTimestamp = timestamp;
        }
    }
    
    //
    // Packages priorities
    //
    NSDictionary *packagesPriorities = [HMParser prioritiesByOID:info[@"prioritized_packages"]];
    [Package prioritizePackagesWithInfo:packagesPriorities context:self.ctx];
    
    // Save the timestamp.
    appCFG.lastUpdateTimestamp = latestTimestamp;
    
    // And we're done.
    HMLOG(TAG, EM_VERBOSE, @"Parsed %@ package/s", @(packages.count));
    [EMDB.sh save];
}

@end
