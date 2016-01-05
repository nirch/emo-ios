//
//  HCFramesProcessingProtocol.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 24/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;

struct HFMaskedSBUFPair {
    CMSampleBufferRef frame;
    CMSampleBufferRef mask;
};
typedef struct HFMaskedSBUFPair HFMaskedSBUFPair;

/**
 * Processing state.
 */
typedef NS_ENUM(NSInteger, HFProcessingState) {
    /**
     * Undefined / Invalid:
     * Undefined or invalid state.
     * This is the default state before the object finished initialization.
     */
    HFProcessingStateUndefined                                      = -1,

    /**
     * Idle:
     * no processing taking place.
     */
    HFProcessingStateIdle                                      = 0,
    
    /**
     * Inspect frames:
     * continuesly inspect frames
     */
    HFProcessingStateInspectFrames                             = 1,
    
    /**
     * Process frames:
     * continuesly process frames
     */
    HFProcessingStateProcessFrames                             = 2,
    
    /**
     * Inspect and process frames:
     * continuesly inspect and process frames
     */
    HFProcessingStateInspectAndProcessFrames                   = 3,
    
    /**
     * Inspect the next (single) frame and process frames:
     * Will inspect and process the next frame.
     * After the next frame is inspected, the state is changed to
     * HCProcessingStateInspectAndProcessFrames and will continue processing frames.
     */
    HFProcessingStateInspectSingleNextFrameAndProcessFrames    = 4
};

/**
 *  Processing protocol.
 *  A general use protocol for processing a sequence of frames/images.
 */
@protocol HFProcessingProtocol <NSObject>

/**
 *  Prepare a single frame for processing or inspection.
 *
 *  @param sampleBuffer CMSampleBufferRef to the frame data to be processed.
 *
 */
-(void)prepareFrame:(CMSampleBufferRef)sampleBuffer;

/**
 *  Inspect a frame.
 *  This will not fully process the frame or change the content.
 *  Will only inspect the current available frame and broadcast info about it,
 *  if required.
 */

/**
 *  Inspect a frame.
 *  This will not fully process the frame or change the content.
 *  Will only inspect the current available frame and broadcast info about it,
 *  if required.
 *
 *  @return NSDictionary (optional) with info about the inspected frame.
 */
-(NSDictionary *)inspectFrame;

/**
 *  Process a frame.
 *
 *  @return CMSampleBufferRef after processing with replaced background for preview/display.
 */
-(CMSampleBufferRef)processFrame;

/**
 *  Process a frame.
 *
 *  @return The mask (used for debugging).
 */
-(CMSampleBufferRef)processFrameReturningMask;

///**
// *  @return HFMaskedSBUFPair latest frame and corresponding transperancy mask. returned as a pair of CMSampleBufferRef.
// */
//-(HFMaskedSBUFPair)latestMaskedSBUFPair;

///**
// *  Latest result - mask (as UIImage)
// *
// *  @return UIImage latest result - mask
// */
//-(UIImage *)latestUIImageMask;

/**
 *  The latest UIImage images: prepared image and transperancy mask.
 *  Will be provided as NSArray with a pair of UIImage and the related time stamp of the frame.
 *
 *  @return NSArray with three items: pair of UIImage images and a NSNumber time stamp.
 */
-(NSArray *)latestUIImageMaskedPair;

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
 *
 *  @param info NSDictionary extra (optional) debug information.
 */
-(void)finishDebuSessionWithInfo:(NSDictionary *)info;

/**
 *  Output queue
 */
@property (weak, atomic) dispatch_queue_t outputQueue;

@end
