//
//  HCRFXCartoon.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import "HCRFX.h"

/**
 *  Cartoon effect. By default reduces the source to 8 colors.
 *  Number of colors of the reduced palette can be changed by setting the numOfColors property.
 */
@interface HCRFXCartoon : HCRFX

/**
 *  Key for the number of colors to reduce the palette to.
 */
extern NSString* const hcrColorsNum;

/**
 *  The number of colors to reduce the palette to.
 */
@property (nonatomic) NSInteger numOfColors;


@end
