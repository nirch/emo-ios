//
//  EMAlertsPermissionVC.h
//  emu
//
//  Created by Aviv Wolf on 3/31/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMAlertsPermissionVC : UIViewController

+(EMAlertsPermissionVC *)alertsPermissionVCInParentVC:(UIViewController *)parentVC;
-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animated;

@end
