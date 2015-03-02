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

@implementation EMPackagesParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    if (info == nil) return;
    
    // Iterate and parse packages
    EMPackageParser *packageParser = [[EMPackageParser alloc] initWithContext:self.ctx];
    NSArray *packages = info[@"packages"];
    for (NSDictionary *packageInfo in packages) {
        packageParser.objectToParse = packageInfo;
        [packageParser parse];
    }
    HMLOG(TAG, EM_VERBOSE, @"Parsed %@ package/s", @(packages.count));
}

@end
