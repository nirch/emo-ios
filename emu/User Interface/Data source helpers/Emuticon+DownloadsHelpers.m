//
//  Emuticon+DownloadsHelpers.m
//  emu
//
//  Created by Aviv Wolf on 10/7/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "Emuticon+DownloadsHelpers.h"
#import "EMDB.h"
#import "EMDownloadsManager2.h"
#import "EMRenderManager2.h"

@implementation Emuticon (DownloadsHelpers)


+(void)enqueueRequiredDownloadsForIndexPaths:(NSArray *)indexPaths
                                         frc:(NSFetchedResultsController *)frc
                                       forUI:(NSString *)forUI
{
    NSMutableDictionary *enqueued = [NSMutableDictionary new];
    for (NSIndexPath *indexPath in indexPaths) {
        Emuticon *emu = [frc objectAtIndexPath:indexPath];
        
        NSDictionary *info =     @{
                                   @"for":forUI,
                                   @"indexPath":indexPath,
                                   @"emuticonOID":emu.oid,
                                   @"packageOID":emu.emuDef.package.oid
                                   };
        
        if ([emu enqueueIfMissingResourcesWithInfo:info]) enqueued[emu.oid] = @YES;
    }
    
    if (enqueued.count > 0) {
        [EMRenderManager2.sh updatePriorities:enqueued];
        [EMDownloadsManager2.sh updatePriorities:enqueued];
        [EMDownloadsManager2.sh manageQueue];
    }
}


-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info
{
    // If already rendered, we don't care about this emu.
    if (self.wasRendered.boolValue) return NO;

    NSArray *missingResourcesNames = [self.emuDef allMissingResourcesNames];
    if (missingResourcesNames.count>0) {
        [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                                 names:missingResourcesNames
                                                  path:self.emuDef.package.name
                                              userInfo:info];
    }
    return YES;
}

@end
