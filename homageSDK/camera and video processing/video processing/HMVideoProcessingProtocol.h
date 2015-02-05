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
 *  Process a single frame.
 *
 *  @param sampleBuffer CMSampleBufferRef to the frame data to be processed.
 *
 *  @return A ref to a buffer after processing.
 */
-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer;

/**
 *  Inspect a frame. 
 *  This will not fully process the frame or change the content.
 *  Will only inspect the current available frame and broadcast info about it,
 *  if required.
 */
-(void)inspectFrame;

@end
