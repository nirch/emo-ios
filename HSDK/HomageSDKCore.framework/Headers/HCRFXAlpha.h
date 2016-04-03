//
//  HCRFXAlpha.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import "HCRFXAnimated.h"

/**
 *  Alpha effect. Also supports keyframe animations / tweening.
 */
@interface HCRFXAlpha : HCRFXAnimated

/**
 *  Alpha value.
 *  0.0 - Layer is transparent.
 *  1.0 - Layer is opaque.
 */
extern NSString* const hcrAlphaValue;

@end
