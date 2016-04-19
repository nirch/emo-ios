//
//  EmuticonDef+DownloadsHelpers.m
//  emu
//
//  Created by Aviv Wolf on 18/04/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EmuticonDef+DownloadsHelpers.h"
#import "EmuticonDef+Logic.h"
#import "EMDB.h"
#import "EMDownloadsManager2.h"

@implementation EmuticonDef (DownloadsHelpers)

-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info
{
    NSArray *missingResourcesNames = [self allMissingResourcesNames];
    if (missingResourcesNames.count < 1) return NO;
    [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                             names:missingResourcesNames
                                              path:self.package.name
                                          userInfo:info];
    return YES;
}

-(BOOL)enqueueIfMissingFullRenderResourcesWithInfo:(NSDictionary *)info
{
    NSArray *missingResourcesNames = [self allMissingFullRenderResourcesNames];
    if (missingResourcesNames.count < 1) return NO;
    [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                             names:missingResourcesNames
                                              path:self.package.name
                                          userInfo:info];
    return YES;
}


@end
