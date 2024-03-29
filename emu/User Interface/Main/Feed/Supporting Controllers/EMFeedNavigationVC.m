//
//  EMFeedNavigationVC.m
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFeedNavigationVC.h"
#import "EMEmusFeedVC.h"
#import "EMDB.h"

@interface EMFeedNavigationVC ()

@end

@implementation EMFeedNavigationVC

+(EMFeedNavigationVC *)feedNavigationVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMFeedNavigationVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"feed navigation vc"];
    return vc;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)vcWasSelectedWithInfo:(NSDictionary *)info
{
    EMEmusFeedVC *feedVC = self.childViewControllers.firstObject;
    NSString *requestedPackageOID = info[emkPackageOID];
    NSString *requestedEmuOID = info[emkEmuticonOID];
    
    if (requestedPackageOID != nil && feedVC != nil) {
        feedVC.requestsPackageOID = requestedPackageOID;
        if (requestedEmuOID) feedVC.requestsEmuOID = requestedEmuOID;

        NSNumber *previousTabIndex = info[@"previousTabIndex"];
        NSNumber *newTabIndex = info[@"newTabIndex"];
        if ([previousTabIndex isEqualToNumber:newTabIndex]) {
            [feedVC consumeNavigationRequests];
        }
    } else {
        [feedVC backToFeedIfNotOnTop];
    }
}

@end
