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
#import "UIView+CommonAnimations.h"

#define BANNER_ADS_TTL 60*3 // Update banner no more than once every 3 minutes

@interface EMAdBannerVC () <
    MPAdViewDelegate
>

@property (nonatomic, weak) EMSimpleBannerAdView *adView;
@property (nonatomic) NSDate *lastSuccessfulLoadTime;

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
    
    self.containerView.hidden = YES;
    self.containerView.alpha = 0;
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
    
    // Refresh ad, but only if TTL passed.
    NSDate *now = [NSDate date];
    NSTimeInterval timePassed = self.lastSuccessfulLoadTime ? [now timeIntervalSinceDate:self.lastSuccessfulLoadTime] : -1;
    if (timePassed < 0 || timePassed > BANNER_ADS_TTL) {
        [self.adView refresh];
    }
    
    // Layout update
    [self.view layoutIfNeeded];
}

#pragma mark - MPAdViewDelegate
- (UIViewController *)viewControllerForPresentingModalView
{
    return self.grandParentVCForModal;
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
    if (self.containerView.alpha == 0 || self.containerView.hidden == YES) {
        self.containerView.hidden = NO;
        [self.containerView animateQuickPopIn];
        self.containerView.alpha = 1;
    }
    self.lastSuccessfulLoadTime = [NSDate date];
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view
{
    [UIView animateWithDuration:0.2 animations:^{
        self.containerView.alpha = 0;
    }];
}

@end
