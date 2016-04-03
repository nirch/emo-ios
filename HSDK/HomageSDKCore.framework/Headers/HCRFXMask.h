//
//  HCRFXMask.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import "HCRFX.h"

/**
 *  A mask effect wrapper.
 *  This effect wrapper wraps three types of different implementation of mask effects.
 *  1) Old style CV mask effect supporting only an image as the mask frame (will be deprecated in the future).
 *  2) Old style CV mask effect supporting only an animated gif as mask frames (will be deprecated in the future).
 *  3) New style CV mask effect supporting any source for mask frames (in the future will be the only supported mask effect).
 */
@interface HCRFXMask : HCRFX

@end
