//
//  EMSilhouetteView.m
//  emu
//
//  Created by Aviv Wolf on 2/19/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMSilhouetteView.h"

@interface EMSilhouetteView()

@property (nonatomic) BOOL effectsAlreadySetup;

@end

@implementation EMSilhouetteView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(void)initGUI
{
    self.effectsAlreadySetup = NO;
}

-(void)setupEffects
{
    if (self.effectsAlreadySetup)
        return;
    
    UIView *silhouette = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:silhouette];
    
    //
    // Add blur effect to the silhouette.
    //
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.bounds;
    [silhouette addSubview:visualEffectView];

    // Mask the blur effect.
    UIImage *maskingImage = [UIImage imageNamed:@"contourMask"];
    CALayer *maskingLayer = [CALayer layer];
    maskingLayer.frame = self.bounds;
    [maskingLayer setContents:(id)[maskingImage CGImage]];
    [visualEffectView.layer setMask:maskingLayer];


    //
    // The contour outline, masked.
    //
    UIImage *outlineImage = [UIImage imageNamed:@"contourOutline"];
    UIImageView *outlineImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    outlineImageView.image = outlineImage;
    outlineImageView.contentMode = UIViewContentModeScaleAspectFit;
    outlineImageView.alpha = 0.5;
    [self addSubview:outlineImageView];
    
    CALayer *maskingLayer2 = [CALayer layer];
    maskingLayer2.frame = self.bounds;
    [maskingLayer2 setContents:(id)[maskingImage CGImage]];
    [outlineImageView.layer setMask:maskingLayer2];
    
    
}

@end
