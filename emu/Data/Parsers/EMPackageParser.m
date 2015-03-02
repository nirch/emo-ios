//
//  EMPackageParser.m
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackageParser.h"
#import "EMDB.h"

@implementation EMPackageParser


-(void)parse
{
    NSDictionary *info = self.objectToParse;
    NSString *oid = [info safeOIDStringForKey:@"oid"];

    Package *pkg = [Package findOrCreateWithID:oid context:self.ctx];
    pkg.name = [info safeStringForKey:@"name"];
    pkg.timeUpdated = [self parseDateOfString:[info safeStringForKey:@"time_updated"]];
}

@end
