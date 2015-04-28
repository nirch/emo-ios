//
//  EMHolySheet.m
//  emu
//
//  Created by Aviv Wolf on 4/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMHolySheet.h"
#import "EmuStyle.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface EMHolySheet()

@property (weak, nonatomic) UIView *visualEffectView;
@property (weak, nonatomic) UIView *parentView;
@property (nonatomic) FLAnimatedImageView *animationView;

@end

@implementation EMHolySheet


-(instancetype)init
{
    self = [super init];
    if (self) {
        self.targetAlpha = 1;
    }
    return self;
}

-(instancetype)initWithSections:(NSArray *)sections
{
    self = [super initWithSections:sections];
    if (self) {
        self.targetAlpha = 1;
    }
    return self;
}

-(void)initVisualEffectView
{
    if (self.visualEffectView) return;

    //
    // Add blur effect to the background.
    //
    CGRect rect = self.parentView.bounds;
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = rect;
    [self.visualEffectView addSubview:visualEffectView];
    
    [self.parentView addSubview:visualEffectView];
    self.visualEffectView = visualEffectView;
    
    self.visualEffectView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.visualEffectView.alpha = self.targetAlpha;
    }];
}

-(void)initThatFuckingBird
{
    if (self.animationView) return;
    
    FLAnimatedImageView *animationView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"activityAnimation" withExtension:@"gif"];
    NSData *animGifData = [NSData dataWithContentsOfURL:url];
    animationView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animGifData];
    [[self.sections[0] superview] addSubview:animationView];
    self.animationView = animationView;
    
    self.animationView.frame = CGRectMake(self.parentView.bounds.size.width/2-35, -85, 80, 80);
    self.animationView.userInteractionEnabled = NO;
    self.animationView.alpha = 0;
    UIView *containerView = self.animationView.superview;
    containerView.clipsToBounds = NO;
}


-(void)showInView:(UIView *)view animated:(BOOL)animated
{
    self.parentView = view;
    if (self.visualEffectView == nil) [self initVisualEffectView];
    [super showInView:view animated:animated];
    if (self.animationView == nil) [self initThatFuckingBird];
    [self initStyle];
    [UIView animateWithDuration:0.5 animations:^{
        self.animationView.alpha = 1;
    }];
}


-(void)dismissAnimated:(BOOL)animated
{
    [self.visualEffectView removeFromSuperview];
    [super dismissAnimated:animated];
    [UIView animateWithDuration:0.1 animations:^{
        self.animationView.alpha = 0;
        [self.animationView stopAnimating];
    }];
}

-(void)initStyle
{
    //
    // Override default styles and use Emu styles instead.
    //
    for (EMHolySheetSection *section in self.sections) {
        section.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.2];
        CALayer *layer = section.layer;
        layer.shadowColor = [UIColor blackColor].CGColor;
        layer.shadowOpacity = 0.1;
        layer.shadowRadius = 4;
        layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
        for (UIButton *button in section.buttons) {
            [button setBackgroundImage:nil forState:UIControlStateNormal];
            [button.titleLabel setFont:[EmuStyle.sh fontForStyle:nil sized:17]];
            [button setTitleColor:[EmuStyle colorButtonText] forState:UIControlStateNormal];
            button.layer.borderWidth = 0;
            if (section.sectionStyle == JGActionSheetButtonStyleDefault) {
                [button setBackgroundColor:[EmuStyle colorButtonBGPositive]];
            } else if (section.sectionStyle == JGActionSheetButtonStyleCancel) {
                [button setBackgroundColor:[EmuStyle colorButtonBGNegative]];
            } else {
                [button setBackgroundColor:[UIColor blackColor]];
            }
        }
    }
}

@end
