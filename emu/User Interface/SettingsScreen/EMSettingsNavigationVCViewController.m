//
//  EMSettingsNavigationVCViewController.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMSettingsNavigationVCViewController.h"

@interface EMSettingsNavigationVCViewController ()

@end

@implementation EMSettingsNavigationVCViewController

+(EMSettingsNavigationVCViewController *)settingsNavVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    EMSettingsNavigationVCViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"settings navigation vc"];
    return vc;
}


@end
