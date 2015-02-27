//
//  EMPackahesParser.m
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

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
    for (NSDictionary *packageInfo in info[@"packages"]) {
        packageParser.objectToParse = packageInfo;
        [packageParser parse];
    }
    [EMDB.sh save];
}

@end
