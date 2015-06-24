//
//  HMVideoProcessingProtocol.h
//  emu
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol HMVideoProcessingProtocol <NSObject>

// Video Processing States
typedef NS_ENUM(NSInteger, HMVideoProcessingState) {
    /** 
     * Idle:
     * no video processing taking place.
     */
    HMVideoProcessingStateIdle                                      = 0,
    
    /**
     * Inspect frames:
     * continuesly inspect frames
     */
    HMVideoProcessingStateInspectFrames                             = 1,
    
    /**
     * Process frames:
     * continuesly process frames
     */
    HMVideoProcessingStateProcessFrames                             = 2,
    
    /**
     * Inspect and process frames:
     * continuesly inspect and process frames
     */
    HMVideoProcessingStateInspectAndProcessFrames                   = 3,
    
    /**
     * Inspect the next (single) frame and process frames:
     * Will inspect and process the next frame.
     * After the next frame is inspected, the state is changed to
     * HMVideoProcessingStateProcessFrames and will continue processing frames.
     */
    HMVideoProcessingStateInspectSingleNextFrameAndProcessFrames    = 4
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
 */
-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer;


/**
 *  Inspect a frame. 
 *  This will not fully process the frame or change the content.
 *  Will only inspect the current available frame and broadcast info about it,
 *  if required.
 */
-(void)inspectFrame;


/**
 *  @return latest output image.
 */
-(void *)latestOutputImage;

/**
 *  Do some clean up operations.
 */
-(void)cleanUp;


@optional
/**
 *  Start a debug session.
 */
-(void)startDebugSession;

/**
 *  Finish a debug session.
 */
-(void)finishDebuSessionWithInfo:(NSDictionary *)info;

@end
