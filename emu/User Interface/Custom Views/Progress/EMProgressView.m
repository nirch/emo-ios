//
//  EMProgressView.m
//  emu
//
//  Created by Aviv Wolf on 2/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMProgressView.h"

@interface EMProgressView()

@property (nonatomic, readwrite) CGFloat value;
@property UIImageView *progressIndicator;

@end

@implementation EMProgressView

-(void)reset
{
    self.value = 0;
    CGRect f = self.bounds;
    f.size.width = 0;
    self.progressIndicator.frame = f;
}

-(void)setValue:(CGFloat)value
       animated:(BOOL)animated
       duration:(NSTimeInterval)duration
{
    // Keep the value in bounds 0.0 ... 1.0
    self.value = MAX(MIN(value, 1.0f), 0.0);
    
    // Update the frame
    CGRect f = self.bounds;
    f.size.width = value * self.bounds.size.width;
    if (animated) {
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionRepeat
                         animations:^{
                             self.progressIndicator.frame = f;
                         } completion:^(BOOL finished) {
                             [self fadeOutAndReset];
                         }];
    } else {
        self.progressIndicator.frame = f;
    }
}

-(void)fadeOutAndReset
{
    [UIView animateWithDuration:1.0
                     animations:^{
                         self.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self reset];
                         self.alpha = 1;
                     }];
}

-(void)initProgressIndicator
{
    self.progressIndicator = [UIImageView new];
    self.progressIndicator.image = [EmuStyle imageWithColor:[UIColor blueColor]];
    [self addSubview:self.progressIndicator];
    [self reset];
}

@end
