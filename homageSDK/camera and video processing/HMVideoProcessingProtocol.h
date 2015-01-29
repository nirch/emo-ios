//
//  HMVideoProcessingProtocol.h
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol HMVideoProcessingProtocol <NSObject>


/**
 *  Reset the video processor to its' starting state.
 */
-(void)prepareForVideoProcessing;

/**
 *  Process a single frame.
 *
 *  @param sampleBuffer CMSampleBufferRef to the frame data to be processed.
 *
 *  @return A ref to a buffer after processing.
 */
-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer;

@end
