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

-(void)refreshPackagesInfo
{
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    [self getRelativeURLNamed:@"packages full"
                   parameters:nil
             notificationName:emkDataUpdatePackages
                         info:nil
                       parser:parser];
}

@end