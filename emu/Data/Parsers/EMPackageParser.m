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
    pkg.label = [info safeStringForKey:@"label"];
    pkg.notificationText = [info safeStringForKey:@"notification_text"];
    pkg.isActive = [info safeBoolNumberForKey:@"active" defaultsValue:@YES];
    pkg.requiredVersion = [info safeStringForKey:@"requiredVersion"];
    pkg.zipppedPackageFileName = [info safeStringForKey:@"zipped_package_file_name"];
    pkg.showOnPacksBar = @(!self.parseForOnboarding);
    pkg.sharingHashtags = [info safeDictionaryForKey:@"sharing_tags" defaultValue:nil];
    pkg.preventVideoWaterMarks = [info safeBoolNumberForKey:@"prevent_video_watermarks" defaultsValue:@NO];
    
    NSNumber *shouldAutoDownload = [info safeBoolNumberForKey:@"should_auto_download"];
    pkg.shouldAutoDownload = shouldAutoDownload? shouldAutoDownload: @YES;
    [pkg updatePriority:@0];
    
    // Featured packs
    pkg.isFeatured = [info safeBoolNumberForKey:@"is_featured" defaultsValue:@NO];
    
    // Icons, banners and posters for the pack
    pkg.iconName = [info safeStringForKey:@"icon_name"];
    pkg.bannerName = [info safeStringForKey:@"banner_name"];
    pkg.bannerWideName = [info safeStringForKey:@"banner_wide_name"];
    pkg.posterName = [info safeStringForKey:@"poster_name"];
    pkg.posterOverlayName = [info safeStringForKey:@"poster_overlay_name"];
    
    // Hidden packages.
    // Some packages:
    //  - are hidden by default (hidden_by_default=YES)
    //  - will be set to hidden=YES (if hidden field never set before)
    //  - will not appear until some process will set the local field to hidden=NO
    NSNumber *isHiddenByDefault = [info safeBoolNumberForKey:@"hidden_by_default"];
    if (pkg.isHidden == nil && isHiddenByDefault != nil && isHiddenByDefault.boolValue) {
        pkg.isHidden = @YES;
    }
    
    // Premium and HD content.
    pkg.hdAvailable = [info safeBoolNumberForKey:@"hd_available" defaultsValue:@NO];
    pkg.hdProductID = [info safeStringForKey:@"hd_product_id"];
    if (pkg.hdUnlocked == nil) pkg.hdUnlocked = @NO;
    
    // If package also include emuticon definitions, parse them all.
    NSInteger index = 0;
    NSArray *emus = info[@"emuticons"];
    if (emus) {
        EMEmuticonParser *emuParser = [[EMEmuticonParser alloc] initWithContext:self.ctx];
        for (NSDictionary *emuInfo in emus) {
            NSString *emuOID = [emuInfo safeOIDStringForKey:@"_id"];
            emuParser.objectToParse = emuInfo;
            emuParser.package = pkg;
            emuParser.defaults = info[@"emuticons_defaults"];
            index++;
            emuParser.incrementalOrder = @(index);
            emuParser.mixedScreenOrder = self.mixedScreenPriorities[emuOID];
            [emuParser parse];
        }
    }
    [pkg createMissingEmuticonObjects];
}

@end
