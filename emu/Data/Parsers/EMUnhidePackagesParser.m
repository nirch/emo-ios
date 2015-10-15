//
//  EMUnhidePackagesParser.m
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMUnhidePackagesParser.h"
#import "EMDB.h"

@implementation EMUnhidePackagesParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    NSMutableArray *missingPacks = [NSMutableArray new];
    NSMutableDictionary *packagesInfo = [NSMutableDictionary new];
    
    // Get info about the packs.
    if (info[@"packages_info"]) {
        for (NSDictionary *packInfo in info[@"packages_info"]) {
            NSString *packOID = [packInfo safeOIDStringForKey:@"_id"];
            if (packOID) packagesInfo[packOID] = packInfo;
        }
    }
     
    // Update state of local pakcs (if exist)
    NSArray *packagesToUnhide = [info safeArrayOfIdsForKey:@"unhides_packages"];
    for (NSString *packOID in packagesToUnhide) {
        Package *pack = [Package findWithID:packOID context:EMDB.sh.context];
        if (pack) {
            pack.isHidden = @NO;
        } else {
            [missingPacks addObject:packOID];
        }
    }

    // Parse info for outside use.
    HMParams *params = [HMParams new];
    [params addKey:@"packages" valueIfNotNil:packagesToUnhide];
    [params addKey:@"packagesInfo" valueIfNotNil:packagesInfo];
    [params addKey:@"missingPackages" valueIfNotNil:missingPacks];
    [params addKey:@"message" valueIfNotNil:[info safeStringForKey:@"success_message"]];
    [params addKey:@"title" valueIfNotNil:[info safeStringForKey:@"success_title"]];
    self.parseInfo = [NSMutableDictionary dictionaryWithDictionary:params.dictionary];

    [EMDB.sh save];
}

@end
