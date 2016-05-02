//
//  EMAdBannerVC.m
//  emu
//
//  Created by Aviv Wolf on 01/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMAdBannerVC.h"
#import "EMSimpleBannerAdView.h"
#import "MPAdView.h"

@interface EMAdBannerVC () <
    MPAdViewDelegate
>

@property (nonatomic, weak) EMSimpleBannerAdView *adView;

@end

@implementation EMAdBannerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    // Add blur effect to the background.
    //
    self.view.backgroundColor = [UIColor clearColor];
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
    [self.view addSubview:visualEffectView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    // Add the ad
    if (self.adView == nil) {
        EMSimpleBannerAdView *adView = [[EMSimpleBannerAdView alloc] init];
        adView.frame = self.view.bounds;
        [self.view addSubview:adView];
        self.adView = adView;
        [self.adView setAdPlacementKey:@"adPlacementFeedBanner"];
        
        if ([self conformsToProtocol:@protocol(MPAdViewDelegate)]) {
            [self.adView setBannerDelegate:(id<MPAdViewDelegate>)self];
        }
    }
    [self.adView refresh];
    [self.view layoutIfNeeded];
}

#pragma mark - MPAdViewDelegate
- (UIViewController *)viewControllerForPresentingModalView
{
    return self.grandParentVCForModal;
}

@end
