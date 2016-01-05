//
//  HFWriterVideo.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 25/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HFWObject.h"
#import "HFWriterProtocol.h"

/**
 *  Used to write frames to a video file.
 *  Conforms to HFWriterProtocol.
 */
@interface HFWriterVideo : HFWObject<
    HFWriterProtocol
>

/**
 *  Controls the sample rate of the audio output.
 *  (10000 is the default value)
 */
@property (nonatomic) double audioSampleRate;

/**
 * Controls the sample rate of the output video file.
 * (41.0 is the default value)
 */
@property (nonatomic) double videoBitsPerPixel;

/**
 * Controls the sample rate of the output mask video file.
 * (41.0 is the default value)
 */
@property (nonatomic) double videoMaskBitsPerPixel;


@end
