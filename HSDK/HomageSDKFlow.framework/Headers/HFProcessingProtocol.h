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
    HFProcessingStateInspectSingleNextFrameAndProcessFrames    = 4,
    
    /**
     *  Post processing a raw captured video.
     */
    HFProcessingStatePostProcessing                            = 5
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
 *  Prepare a single frame for processing or inspection
 *
 *  @param image - A raw UIImage object with the image to process/inspect.
 *  @param timeStamp the related time stamp for this frame.
 */
-(void)prepareFrameFromUIImage:(UIImage *)image timeStamp:(long long)timeStamp;

/**
 *  Prepare a single frame for processing or inspection
 *
 *  @param bytesArray A raw byte array of the image data.
 *  @param timeStamp the related time stamp for this frame.
 */
-(void)prepareFrameFromBytesArray:(GLubyte *)bytesArray timeStamp:(long long)timeStamp;

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
 */
-(void)processFrame;

/**
 *  The byte array with the raw data of the computed mask.
 *
 *  @return GLubyte array with the data of the computed mask.
 */
-(NSData *)resultMaskData;

/**
 *  Do some clean up operations.
 */
-(void)cleanUp;

#pragma mark - Results
/**
 *  Used for debugging. Will convert and return the internally stored image as a UIImage object.
 *
 *  @return UIImage object created using the internally stored prepared image data (use for debugging).
 */
-(UIImage *)preparedUIImage;

/**
 *  Will convert and return the internally stored computed mask as a UIImage object.
 *
 *  @return UIImage object created using the internally stored computed mask.
 */
-(UIImage *)resultMaskUIImage;

/**
 *  asdasd
 *
 *  @return dfgsdfg
 */
-(UIImage *)resultDisplayImage;

/**
 *  The latest UIImage images: prepared image and transperancy mask.
 *  Will be provided as NSArray with a pair of UIImage and the related time stamp of the frame.
 *
 *  @return NSArray with three items: pair of UIImage images and a NSNumber time stamp.
 */
-(NSArray *)latestUIImageMaskedPair;


#pragma mark - Debugging
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
