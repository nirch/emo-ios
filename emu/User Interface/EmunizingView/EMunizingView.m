//
//  EMunizingView.m
//  emu
//
//  Created by Aviv Wolf on 2/24/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMunizingView.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface EMunizingView()

@property (nonatomic, readwrite) BOOL isAnimating;
@property (nonatomic, weak) FLAnimatedImageView *animationView;
@property (nonatomic, weak) UIImageView *activityImageView;

@end

@implementation EMunizingView

-(void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    if (self.animationView == nil) {
        FLAnimatedImageView *animationView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"activityAnimation" withExtension:@"gif"];
        NSData *animGifData = [NSData dataWithContentsOfURL:url];
        animationView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animGifData];
        [self addSubview:animationView];
        self.animationView = animationView;
    }
    
    if (self.activityImageView == nil) {
        UIImage *image = [UIImage imageNamed:@"activity"];
        UIImageView *activityImageView = [[UIImageView alloc] initWithImage:image];
        activityImageView.frame = self.bounds;
        [self addSubview:activityImageView];
        self.activityImageView = activityImageView;
    }
    
    
    self.animationView.center = self.center;
    [self stopAnimating];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat padding = self.bounds.size.width / 10.0;
    self.animationView.frame = CGRectInset(self.bounds, padding, padding);
    
    // Hack - The animation provided by the designer is not centered properly
    // move it to the right position
    CGPoint p = self.animationView.center;
    p.x = p.x - padding / 20.0;
    p.y = p.y - padding / 18.0;
    self.animationView.center = p;
}

#pragma mark - Animating
-(void)startAnimating
{
    self.isAnimating = YES;

    // Spinning
    CGFloat duration = 2.0;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: -M_PI * 2.0 * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.activityImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    // Animated gif
    [self.animationView startAnimating];
    
    self.hidden = NO;
    self.alpha = 0;

    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 1;
    }];
}


-(void)stopAnimating
{
    self.isAnimating = NO;
    [self.animationView stopAnimating];
    [self.activityImageView.layer removeAllAnimations];
    self.hidden = YES;
}


@end
