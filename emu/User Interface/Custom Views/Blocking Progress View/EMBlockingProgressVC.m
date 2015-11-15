//
//  EMBlockingProgressViewController.m
//  emu
//
//  Created by Aviv Wolf on 06/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMBlockingProgressVC.h"
#import "EMunizingView.h"

@interface EMBlockingProgressVC ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurryBG;
@property (weak, nonatomic) IBOutlet EMunizingView *guiEmunizingView;
@property (weak, nonatomic) IBOutlet UIProgressView *guiProgressView;
@property (weak, nonatomic) IBOutlet UILabel *guiTitle;

@end

@implementation EMBlockingProgressVC

+(EMBlockingProgressVC *)blockingProgressVCInParentVC:(UIViewController *)parentVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"EMBlockingProgressVC" bundle:nil];
    EMBlockingProgressVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"blocking progress vc"];
    [parentVC addChildViewController:vc];
    [parentVC.view addSubview:vc.view];
    vc.view.frame = parentVC.view.bounds;
    return vc;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.alpha = 0;
    self.guiProgressView.alpha = 0;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.guiEmunizingView setup];
    [self.guiEmunizingView startAnimating];
    self.guiProgressView.progress = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //
    // Add blur effect to the background.
    //
    self.guiBlurryBG.backgroundColor = [UIColor clearColor];
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.guiBlurryBG.bounds;
    [self.guiBlurryBG addSubview:visualEffectView];
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

-(void)updateProgress:(CGFloat)progress animated:(BOOL)animated
{
    [self.guiProgressView setProgress:progress animated:animated];
    self.guiProgressView.alpha = 1.0f;
}

-(void)updateTitle:(NSString *)title
{
    self.guiTitle.text = title;
}

-(void)done
{
    [self hideAnimated:YES];
    dispatch_after(DTIME(0.4), dispatch_get_main_queue(), ^{
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    });
}

@end
