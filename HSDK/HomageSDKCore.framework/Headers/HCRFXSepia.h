//
//  HCRFXSepia.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "HCRFX.h"

/**
 *  Sepia effect.
 *  Possible to set three values on this effect:
 *   - levelRed 0.0-1.0 value for the red channel
 *   - levelGreen 0.0-1.0 value for the green channel
 *   - levelBlue 0.0-1.0 value for the blue channel
 *
 *   Default values used: RGB=(0.439,0.258,0.078)
 */
@interface HCRFXSepia : HCRFX

/**
 *  Key for the rgb levels of the effect.
 */
extern NSString* const hcrRGBLevels;

/**
 *  Red level of the effect (0.0 - 1.0)
 */
@property (nonatomic) CGFloat levelRed;

/**
 *  Green level of the effect (0.0 - 1.0)
 */
@property (nonatomic) CGFloat levelGreen;

/**
 *  Blue level of the effect (0.0 - 1.0)
 */
@property (nonatomic) CGFloat levelBlue;

@end
