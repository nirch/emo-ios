//
//  EMAlertsPermissionVC.m
//  emu
//
//  Created by Aviv Wolf on 3/31/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMAlertsPermissionVC.h"

@interface EMAlertsPermissionVC ()

@end

@implementation EMAlertsPermissionVC

+(EMAlertsPermissionVC *)alertsPermissionVCInParentVC:(UIViewController *)parentVC
{
    EMAlertsPermissionVC *alertsPermissionVC = [[EMAlertsPermissionVC alloc] initWithNibName:@"SplashView" bundle:nil];
    alertsPermissionVC.view.frame = parentVC.view.bounds;
    [parentVC.view addSubview:alertsPermissionVC.view];
    [parentVC addChildViewController:alertsPermissionVC];
    [alertsPermissionVC hideAnimated:NO];
    return alertsPermissionVC;
}


-(void)showAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self showAnimated:NO];
        }];
        return;
    }
    self.view.alpha = 1;
}


-(void)hideAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideAnimated:NO];
        }];
        return;
    }
    self.view.alpha = 0;
}

@end
