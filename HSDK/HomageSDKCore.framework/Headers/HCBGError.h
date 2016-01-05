//
//  HCBGError.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 15/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HCError.h"

extern NSString* const hckErrorDomainBackground;

/**
 *  hckBGError - Background removal and detection errors.
 */
typedef NS_ENUM(NSInteger, hckBGError) {
    /**
     * Configuration error.
     * A required ctr / contour file couldn't be found at path / is missing.
     * You can't use the BG Removal algorithm without a valid ctr file.
     */
    hckBGErrorMissingCTRFile            = 1000,
    
    /**
     *  No error during configuration validation but failed to initialize the bg removal algorithm.
     *  report this error to the SDK developer. Code example of how you initialized the object will be apreciated.
     */
    hckBGErrorFailedToInit = 2000,
    
    /**
     *  Failed to process or inspect image (wrong size).
     */
    hckBGErrorInvalidSize = 3000,
};

/**
 *  HCError class, representing configuration and process errors of the background removal / detection algorithm.
 *  See hckBGError for all possible error codes and meaning.
 */
@interface HCBGError : HCError

@end
