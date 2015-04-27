//
//  EMAlertsPermissionVC.m
//  emu
//
//  Created by Aviv Wolf on 3/31/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMAlertsPermissionVC.h"
#import <FLAnimatedImage.h>
#import <FLAnimatedImageView.h>

@interface EMAlertsPermissionVC ()

@property (weak, nonatomic) IBOutlet UIView *blurryView;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiEmuBird;
@property (weak, nonatomic) IBOutlet UIView *guiAlertView;
@property (weak, nonatomic) IBOutlet UIButton *guiOKButton;
@property (weak, nonatomic) IBOutlet UIButton *guiNotNowButton;


@property (nonatomic) BOOL alreadyInitializedGUI;

@end

@implementation EMAlertsPermissionVC

+(EMAlertsPermissionVC *)alertsPermissionVCInParentVC:(UIViewController *)parentVC
{
    EMAlertsPermissionVC *alertsPermissionVC = [[EMAlertsPermissionVC alloc] initWithNibName:@"EMAlertsPermissionVC" bundle:nil];
    alertsPermissionVC.view.frame = parentVC.view.bounds;
    [parentVC.view addSubview:alertsPermissionVC.view];
    [parentVC addChildViewController:alertsPermissionVC];
    [alertsPermissionVC hideAnimated:NO];
    return alertsPermissionVC;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.alreadyInitializedGUI = NO;
}

-(void)initGUI
{
    if (self.alreadyInitializedGUI) return;
    self.view.backgroundColor = [UIColor clearColor];

    //
    // Add blur effect to the background.
    //
    self.blurryView.backgroundColor = [UIColor clearColor];
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.blurryView.bounds;
    [self.blurryView addSubview:visualEffectView];
    
    //
    // Emu birdy
    //
    self.guiEmuBird.backgroundColor = [UIColor clearColor];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"activityAnimation" withExtension:@"gif"];
    NSData *animGifData = [NSData dataWithContentsOfURL:url];
    self.guiEmuBird.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animGifData];
    [self.guiEmuBird startAnimating];

    
    //
    // The alert
    //
    UIColor *borderColor = [UIColor lightGrayColor];
    
    CALayer *layer = self.guiAlertView.layer;
    layer.borderColor = borderColor.CGColor;
    layer.borderWidth = 0.5;
    layer.cornerRadius = 8;
    layer.shadowRadius = 20;
    layer.shadowOpacity = 0.2;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
    
    layer = self.guiOKButton.layer;
    layer.borderWidth = 0.5;
    layer.borderColor = borderColor.CGColor;
    
    layer = self.guiNotNowButton.layer;
    layer.borderWidth = 0.5;
    layer.borderColor = borderColor.CGColor;
}

#pragma mark - Layout
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self initGUI];
}


#pragma mark - Show/Hide
-(void)showAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.7
                              delay:0
             usingSpringWithDamping:0.44
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self showAnimated:NO];
                         } completion:nil];
        return;
    }
    self.view.transform = CGAffineTransformIdentity;
}


-(void)hideAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideAnimated:NO];
        }];
        return;
    }
    self.view.transform = CGAffineTransformMakeTranslation(0, -1000);
}

#pragma mark - Confirm alerts
-(void)confirmAlerts
{
    // Local notifications
    UIUserNotificationType notificationTypes =
        UIUserNotificationTypeAlert |
        UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    // Remote notifications.
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedOKButton:(id)sender
{
    [self confirmAlerts];
    [self hideAnimated:YES];
    [HMPanel.sh analyticsEvent:AK_E_NOTIFICATIONS_USER_OKAY];
}

- (IBAction)onPressedNoButton:(id)sender
{
    [self hideAnimated:YES];
    [HMPanel.sh analyticsEvent:AK_E_NOTIFICATIONS_USER_NOT_NOW];
}


@end
