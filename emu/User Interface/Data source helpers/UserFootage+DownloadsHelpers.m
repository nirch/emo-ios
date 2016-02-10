//
//  UserFootage+DownloadsHelpers.m
//  emu
//
//  Created by Aviv Wolf on 10/7/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UserFootage+DownloadsHelpers.h"
#import "EMDB+Files.h"
#import "EMDownloadsManager2.h"

@implementation UserFootage (DownloadsHelpers)

-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info
{
    NSArray *missingResourcesNames = [self allMissingRemoteFiles];
    if (missingResourcesNames.count>0) {
        [EMDownloadsManager2.sh enqueueResourcesForOID:self.oid
                                                 names:missingResourcesNames
                                                  path:@"footages"
                                              userInfo:info
                                                taskType:DL_TASK_TYPE_FOOTAGES_FILES];
        [EMDownloadsManager2.sh manageQueue];
    }
    return YES;
}

@end
