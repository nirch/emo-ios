//
//  EMGradientView.m
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMGradientView.h"

@interface EMGradientView()

@property (nonatomic, weak) PCGradient* gradient;

@end

@implementation EMGradientView

-(void)setGradientName:(NSString *)gradientName
{
    id o = [EmuStyle class];
    SEL gradientSelector = NSSelectorFromString(gradientName);
    if ([o respondsToSelector:gradientSelector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        self.gradient = [o performSelector:gradientSelector withObject:nil];
        #pragma clang diagnostic pop
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.gradient == nil)
        return;
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    
    // Set to bounds.
    CGRect currentBounds = self.bounds;
    
    // Draw the linear gradient.
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), currentBounds.size.height);
    CGContextDrawLinearGradient(currentContext,
                                self.gradient.CGGradient,
                                topCenter,
                                bottomCenter,
                                0);
    
    // Release and done
    CGColorSpaceRelease(rgbColorspace);
}

@end
