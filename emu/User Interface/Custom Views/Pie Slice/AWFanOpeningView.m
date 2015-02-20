//
//  AWPieSliceView.m
//  Aviv Wolf
//
//  Created by Aviv Wolf on 1/10/12.
//  Copyright (c) 2012 Aviv Wolf. All rights reserved.
//

#import "AWFanOpeningView.h"
#import "AWFanOpeningLayer.h"

@interface AWFanOpeningView()

@property (nonatomic, readonly) CALayer *containerLayer;

@end

@implementation AWFanOpeningView

@synthesize startAngle = _startAngle;
@synthesize endAngle = _endAngle;

#pragma mark - Initializations
-(void)doInitialSetup
{
    _containerLayer = [CALayer layer];
    _startAngle = 0;
    _endAngle = 0;
    self.layer.mask = self.containerLayer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self doInitialSetup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self doInitialSetup];
    }
    return self;
}


#pragma mark - Slice Value
-(void)updateSlice
{
    self.containerLayer.frame = self.bounds;
    
    // Init sublayers if needed
    if (self.containerLayer.sublayers==0) {
        AWFanOpeningLayer *slice = [AWFanOpeningLayer layer];
        slice.frame = self.bounds;
        [self.containerLayer addSublayer:slice];
    }
    
    // Set the angles on the slice
    AWFanOpeningLayer *slice = self.containerLayer.sublayers[0];
    slice.startAngle = self.startAngle/360.0 * 2 * M_PI;
    slice.endAngle = self.endAngle/360.0 * 2 * M_PI;
    
    [slice setNeedsDisplay];
}

@end
