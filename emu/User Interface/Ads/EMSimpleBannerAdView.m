//
//  EMSimpleBannerAdView.m
//  emu
//
//  Created by Aviv Wolf on 01/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMSimpleBannerAdView.h"
#import <MPAdView.h>
#import <MPConstants.h>

@interface EMSimpleBannerAdView()

@property (nonatomic, weak) MPAdView *adView;

@end

@implementation EMSimpleBannerAdView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(void)setAdPlacementKey:(NSString *)adPlacementKey
{
    _adPlacementKey = adPlacementKey;
    [self updateAd];
}

-(NSString *)adUnitId
{
    return @"b1db1c2fa8064074bda433b6184e0a5e";
}

-(void)updateAd
{
    if (self.adView == nil) {
        // Initialize the ad view
        NSString *adUnitId = [self adUnitId];
        MPAdView *adView = [[MPAdView alloc] initWithAdUnitId:adUnitId size:MOPUB_BANNER_SIZE];
        CGRect frame = CGRectMake(0,0,MOPUB_BANNER_SIZE.width, MOPUB_BANNER_SIZE.height);
        [self addSubview:adView];
        adView.frame = frame;
        self.adView = adView;
    }
    [self.adView loadAd];
}

-(void)refresh
{
    [self.adView loadAd];
}

-(CGPoint)middlePoint
{
    CGPoint point = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    return point;
}

-(void)layoutSubviews
{
    self.adView.center = [self convertPoint:self.center fromView:self.superview];
    NSLog(@">>>> %@", self.adView);
}

-(void)setBannerDelegate:(id<MPAdViewDelegate>)delegate
{
    self.adView.delegate = delegate;
}

@end
