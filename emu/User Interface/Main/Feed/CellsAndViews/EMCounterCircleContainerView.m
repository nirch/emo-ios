//
//  CounterCircleContainerView.m
//  emu
//
//  Created by Aviv Wolf on 10/8/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMCounterCircleContainerView.h"

@implementation EMCounterCircleContainerView

- (void)drawRect:(CGRect)rect {
    //// HalfCircle Drawing
    CGRect halfCircleRect = CGRectMake(2, 2, 24, 24);
    UIBezierPath* halfCirclePath = [UIBezierPath bezierPath];
    [halfCirclePath addArcWithCenter: CGPointMake(0, 0) radius: CGRectGetWidth(halfCircleRect) / 2 startAngle: -180 * M_PI/180 endAngle: 0 * M_PI/180 clockwise: YES];
    
    CGAffineTransform halfCircleTransform = CGAffineTransformMakeTranslation(CGRectGetMidX(halfCircleRect), CGRectGetMidY(halfCircleRect));
    halfCircleTransform = CGAffineTransformScale(halfCircleTransform, 1, CGRectGetHeight(halfCircleRect) / CGRectGetWidth(halfCircleRect));
    [halfCirclePath applyTransform: halfCircleTransform];
    
    [EmuBaseStyle.colorMainBG1 setFill];
    [halfCirclePath fill];
    [EmuBaseStyle.colorMain1 setStroke];
    halfCirclePath.lineWidth = 1;
    [halfCirclePath stroke];

}


@end
