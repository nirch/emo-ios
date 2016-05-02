//
//  EMAdLoader.m
//  emu
//
//  Created by Aviv Wolf on 27/04/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMAdLoader.h"
#import <MPStaticNativeAdRenderer.h>
#import <MPStaticNativeAdRendererSettings.h>
#import <MPNativeAdRequest.h>
#import <MPNativeAdConstants.h>
#import <MPNativeAdRequestTargeting.h>
#import <MPNativeAd.h>
#import <MPNativeAdDelegate.h>
#import "EMAdView.h"

@interface EMAdLoader()<
    MPNativeAdDelegate
>

@property (weak, nonatomic) UIView *containerView;
@property (weak, nonatomic) UIViewController *containerVC;
@property (nonatomic) MPNativeAd *nativeAd;

@end

@implementation EMAdLoader

-(NSString *)adUnitIdentifier
{
    return @"136aab6a576940bea22191ad6805215e";
}

-(void)createOrRefreshInContainer:(UIView *)containerView containerVC:(UIViewController *)containerVC
{
    self.containerView = containerView;
    self.containerVC = containerVC;
    
    MPStaticNativeAdRendererSettings *settings = [[MPStaticNativeAdRendererSettings alloc] init];
    settings.renderingViewClass = [EMAdView class];
    
    MPNativeAdRendererConfiguration *config = [MPStaticNativeAdRenderer rendererConfigurationWithRendererSettings:settings];
    MPNativeAdRequest *adRequest = [MPNativeAdRequest requestWithAdUnitIdentifier:[self adUnitIdentifier] rendererConfigurations:@[config]];
    MPNativeAdRequestTargeting *targeting = [MPNativeAdRequestTargeting targeting];
    targeting.desiredAssets = [NSSet setWithObjects:kAdTitleKey, kAdTextKey, kAdCTATextKey, kAdIconImageKey, kAdMainImageKey, kAdStarRatingKey, nil]; //The constants correspond to the 6 elements of MoPub native ads
    adRequest.targeting = targeting;
    
    [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response, NSError *error) {
        if (error) {
            
        } else {
            self.nativeAd = response;
            self.nativeAd.delegate = self;
            UIView *nativeAdView = [response retrieveAdViewWithError:nil];
            nativeAdView.frame = containerView.bounds;
            [containerView addSubview:nativeAdView];
        }
    }];
}

#pragma mark - MPNativeAdDelegate
-(UIViewController *)viewControllerForPresentingModalView
{
    return self.containerVC;
}

@end
