//
//  HMGreenMachine.h
//  homage sdk
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMVideoProcessingProtocol.h"
#import <AVFoundation/AVFoundation.h>

#import "HMGMError.h"

@interface HMGreenMachine : NSObject<
    HMVideoProcessingProtocol
>

/**
 *  Factory for HMGreenMachine. Creates a new instance of the green machine
 *  it and validates initialization.
 *
 *  @param bgImageFilename A background image. Image must not contain an alpha channel.
 *  @param contourFileName Name of the corresponding ctr file.
 *  @param error           out error (HMGMError) or nil if no error found.
 *
 *  @return HMGreenMachine instance if initialized properly. nil if error found in initialization.
 */
+(HMGreenMachine *)greenMachineWithBGImageFileName:(NSString *)bgImageFilename
                                   contourFileName:(NSString *)contourFileName
                                             error:(HMGMError **)error;


/**
 *  Initializes and validates the green machine instance.
 *
 *  @param bgImageFilename A background image. Image must not contain an alpha channel.
 *  @param contourFileName Name of the corresponding ctr file.
 *  @param error           out error (HMGMError) or nil if no error found.
 *
 *  @return Initialized green machine object. nil if error found in initialization.
 */
-(id)initWithBGImageFileName:(NSString *)bgImageFilename
             contourFileName:(NSString *)contourFileName
                       error:(HMGMError **)error;


@end
