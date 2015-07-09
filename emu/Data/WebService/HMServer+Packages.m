//
//  HMServer+Packages.m
//  emu
//
//  Created by Aviv Wolf on 3/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMServer+Packages.h"
#import "EMPackagesParser.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"

@implementation HMServer (Packages)

-(void)fetchPackagesFullInfoWithInfo:(NSDictionary *)info
{
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    [self getRelativeURLNamed:@"packages full"
                   parameters:nil
             notificationName:emkDataUpdatedPackages
                         info:info
                       parser:parser];
}


-(void)fetchPackagesUpdatesSince:(NSNumber *)timestamp withInfo:(NSDictionary *)info
{
    if (timestamp == nil ||
        ![timestamp isKindOfClass:[NSNumber class]] ||
        [timestamp isEqualToNumber:@0]) {
        // Fetch it all.
        [self fetchPackagesFullInfoWithInfo:info];
        return;
    }
    
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    [self getRelativeURLNamed:@"packages update"
                   parameters:@{@"after":[timestamp stringValue]}
             notificationName:emkDataUpdatedPackages
                         info:info
                       parser:parser];
}


@end
