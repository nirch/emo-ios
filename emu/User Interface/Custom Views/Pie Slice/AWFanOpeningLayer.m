//
//  AWPieSliceLayer.m
//  Aviv Wolf
//
//  Created by Aviv Wolf on 1/10/12.
//  Copyright (c) 2012 Aviv Wolf. All rights reserved.
//

#import "AWFanOpeningLayer.h"

@implementation AWFanOpeningLayer

@dynamic startAngle, endAngle;

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
    anim.fromValue = [[self presentationLayer] valueForKey:key];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    anim.duration = 0.7;
    return anim;
}

-(id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"startAngle"] ||
        [event isEqualToString:@"endAngle"]) {
        return [self makeAnimationForKey:event];
    }
    return [super actionForKey:event];
}

- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer]) {
        if ([layer isKindOfClass:[AWFanOpeningLayer class]]) {
            AWFanOpeningLayer *other = (AWFanOpeningLayer *)layer;
            self.startAngle = other.startAngle;
            self.endAngle = other.endAngle;
        }
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}


-(void)drawInContext:(CGContextRef)ctx
{
    double startAngle = self.startAngle - M_PI_2;
    double endAngle = self.endAngle - M_PI_2;
    
    // Create the path
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat radius = MIN(center.x, center.y) * 4;
    center.y *= 1.6;
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, center.x, center.y);
    
    CGPoint p1 = CGPointMake(center.x + radius * cosf(startAngle), center.y + radius * sinf(startAngle));
    CGContextAddLineToPoint(ctx, p1.x, p1.y);
    
    int clockwise = startAngle > endAngle;
    CGContextAddArc(ctx, center.x, center.y, radius, startAngle, endAngle, clockwise);
    
    // Close the path
    CGContextClosePath(ctx);
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(ctx, 0);

    // Draw the path with fill
    CGContextDrawPath(ctx, kCGPathFillStroke);
}

@end
