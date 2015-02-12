//
//  HMVideoProcessingProtocol.h
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol HMVideoProcessingProtocol <NSObject>

// Video Processing States
typedef NS_ENUM(NSInteger, HMVideoProcessingState) {
    HMVideoProcessingStateIdle                                  = 0,
    HMVideoProcessingStateInspectFrames                         = 1,
    HMVideoProcessingStateProcessFrames                         = 2,
    HMVideoProcessingStateInspectAndProcessFrames               = 3
};

/**
 *  Output queue (optional)
 */
@property (weak, atomic) dispatch_queue_t outputQueue;


/**
 *  Prepare a single frame for processing or inspection.
 *
 *  @param sampleBuffer sampleBuffer CMSampleBufferRef to the frame data to be processed.
 *
 */
-(void)prepareFrame:(CMSampleBufferRef)sampleBuffer;


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
