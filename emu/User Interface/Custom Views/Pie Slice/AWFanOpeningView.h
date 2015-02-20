//
//  AWPieSliceView.h
//  Aviv Wolf
//
//  Created by Aviv Wolf on 1/10/12.
//  Copyright (c) 2012 Aviv Wolf. All rights reserved.
//

@interface AWFanOpeningView : UIView

/**
 *  Start angle in degrees. 
 *  (will be converted to radians)
 */
@property (atomic) CGFloat startAngle;


/**
 *  Start angle in degrees.
 *  (will be converted to radians)
 */
@property (atomic) CGFloat endAngle;


-(void)updateSlice;

@end
