//
//  EMPackageParser.m
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackageParser.h"
#import "EMDB.h"
#import "EMEmuticonParser.h"

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
    NSString *oid = [info safeOIDStringForKey:@"_id"];

    Package *pkg = [Package findOrCreateWithID:oid context:self.ctx];
    pkg.name = [info safeStringForKey:@"name"];
    pkg.timeUpdated = [self parseDateOfString:[info safeStringForKey:@"last_update"]];
    pkg.firstPublishedOn = [self parseDateOfString:[info safeStringForKey:@"first_published_on"]];
    pkg.iconName = [info safeStringForKey:@"icon_name"];
    pkg.label = [info safeStringForKey:@"label"];
    pkg.priority = self.incrementalOrder? self.incrementalOrder:@(9999);
    pkg.notificationText = [info safeStringForKey:@"notification_text"];
    pkg.isActive = [info safeBoolNumberForKey:@"is_active" defaultsValue:@YES];
    pkg.requiredVersion = [info safeStringForKey:@"requiredVersion"];
    
    // If package also include emuticon definitions, parse them all.
    NSInteger index = 0;
    NSArray *emus = info[@"emuticons"];
    if (emus) {
        EMEmuticonParser *emuParser = [[EMEmuticonParser alloc] initWithContext:self.ctx];
        for (NSDictionary *emuInfo in emus) {
            emuParser.objectToParse = emuInfo;
            emuParser.package = pkg;
            emuParser.defaults = info[@"emuticons_defaults"];
            index++;
            emuParser.incrementalOrder = @(index);
            [emuParser parse];
        }
    }
}

@end
