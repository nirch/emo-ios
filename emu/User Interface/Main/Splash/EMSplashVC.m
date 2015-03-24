//
//  EMSplashVC.m
//  emu
//
//  Created by Aviv Wolf on 3/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMSplashVC.h"

@interface EMSplashVC ()

@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@end

@implementation EMSplashVC

+(EMSplashVC *)splashVCInParentVC:(UIViewController *)parentVC
{
    EMSplashVC *splashVC = [[EMSplashVC alloc] initWithNibName:@"SplashView" bundle:nil];
    splashVC.view.frame = parentVC.view.bounds;
    [parentVC.view addSubview:splashVC.view];
    [parentVC addChildViewController:splashVC];
    [splashVC hideAnimated:NO];
    return splashVC;
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
    [self.guiActivity startAnimating];
}


-(void)hideAnimated:(BOOL)animted
{
    if (animted) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideAnimated:NO];
        }];
        return;
    }
    
    self.view.alpha = 0;
    [self.guiActivity stopAnimating];
}

-(void)setText:(NSString *)text
{
    self.guiLabel.text = text;
}

@end
