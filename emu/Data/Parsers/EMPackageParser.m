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
    /*
     Example for a package meta data
     {
     "oid":{"$oid": "2"},
     "icon_name":"hate_icon.png",
     "name":"hate",
     "label":"Hate!",
     "time_updated":"2014-07-29T12:20:23"
     }
     */
    
    NSDictionary *info = self.objectToParse;
    NSString *oid = [info safeOIDStringForKey:@"oid"];

    Package *pkg = [Package findOrCreateWithID:oid context:self.ctx];
    pkg.name = [info safeStringForKey:@"name"];
    pkg.timeUpdated = [self parseDateOfString:[info safeStringForKey:@"time_updated"]];
    pkg.iconName = [info safeStringForKey:@"icon_name"];
    pkg.label = [info safeStringForKey:@"label"];
}

@end
