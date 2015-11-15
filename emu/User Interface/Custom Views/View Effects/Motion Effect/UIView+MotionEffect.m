//
//  UIView+MotionEffect.m
//  ColorClock
//
//  Created by Aviv Wolf on 10/15/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

#import "UIView+MotionEffect.h"

@implementation UIView (MotionEffect)

-(void)addMotionEffectWithAmountX:(double)amountX amountY:(double)amountY
{
    // Set horizontal effect
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-amountX);
    horizontalMotionEffect.maximumRelativeValue = @(amountX);
    

    // Set vertical effect
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-amountY);
    verticalMotionEffect.maximumRelativeValue = @(amountY);

    // Create group to combine both
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    // Add the effect
    [self addMotionEffect:group];
}

-(void)addMotionEffectWithAmount:(double)amount
{
    [self addMotionEffectWithAmountX:amount amountY:amount];
}



@end
