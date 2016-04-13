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

@implementation Emuticon (DownloadsHelpers)


+(void)enqueueRequiredDownloadsForIndexPaths:(NSArray *)indexPaths
                                         frc:(NSFetchedResultsController *)frc
                                       forUI:(NSString *)forUI
{
    NSMutableDictionary *enqueued = [NSMutableDictionary new];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section >= frc.sections.count) continue;
        if (indexPath.item >= [[frc.sections[indexPath.section] objects] count]) continue;
        
        Emuticon *emu = [frc objectAtIndexPath:indexPath];
        NSDictionary *info =     @{
                                   @"for":forUI,
                                   emkIndexPath:indexPath,
                                   emkEmuticonOID:emu.oid,
                                   emkPackageOID:emu.emuDef.package.oid
                                   };
        
        if ([emu enqueueIfMissingResourcesWithInfo:info]) enqueued[emu.oid] = @YES;
    }
    
    if (enqueued.count > 0) {
        [EMDownloadsManager2.sh updatePriorities:enqueued];
        [EMDownloadsManager2.sh manageQueue];
    }
}


-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info
{
    // If already rendered, we don't care about this emu.
    if (self.wasRendered.boolValue) return NO;

    NSArray *missingResourcesNames = [self.emuDef allMissingResourcesNames];
    if (missingResourcesNames.count > 0) {
        [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                                 names:missingResourcesNames
                                                  path:self.emuDef.package.name
                                              userInfo:info];
    }
    return YES;
}

-(BOOL)enqueueIfMissingFullRenderResourcesWithInfo:(NSDictionary *)info
{
    NSArray *missingResourcesNames = [self.emuDef allMissingFullRenderResourcesNames];
    if (missingResourcesNames.count < 1)
        return NO;
    
    [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                             names:missingResourcesNames
                                              path:self.emuDef.package.name
                                          userInfo:info];
    return YES;
}

-(void)enqueueMissingRemoteFootageFilesWithInfo:(NSDictionary *)info
{
    NSArray *missingResourcesNames = [self allMissingRemoteFootageFiles];
    if (missingResourcesNames.count>0) {
        [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                                 names:missingResourcesNames
                                                  path:@"footages"
                                              userInfo:info
                                              taskType:emkDLTaskTypeFootages];
        [EMDownloadsManager2.sh manageQueue];
    }
}


@end
