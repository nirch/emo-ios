//
//  UIView+CommonAnimations.m
//  emu
//
//  Created by Aviv Wolf on 10/8/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UIView+CommonAnimations.h"

@implementation UIView (CommonAnimations)

-(void)animateQuickPopIn
{
    self.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    [UIView animateWithDuration:0.3 delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

-(void)animateShortVibration
{
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(03.0f, 0.0f, 0) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 10.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 4.0f ;
    anim.duration = 0.07f ;
    [self.layer addAnimation:anim forKey:nil] ;
}

@end
