//
//  HMWriterProtocol.h
//  emu
//
//  Created by Aviv Wolf on 2/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

@protocol HMWriterProtocol <NSObject>

typedef NS_ENUM(NSInteger, HMWritesFramesOfType) {
    HMWritesFramesOfTypeAnyType                     = 0,
    HMWritesFramesOfTypeImageType                   = 1,
    HMWritesFramesOfTypeCMSampleBufferRef           = 2
};

@required
@property (nonatomic) HMWritesFramesOfType writesFramesOfType;

/**
 *  Final initializations, before starting.
 *  must be called before writing the first frame.
 */
-(void)prepareWithInfo:(NSDictionary *)info;


/**
 *  Finish up, clean up temp files and resources and close output files as needed.
 *  will be called after the last frame is written.
 */
-(NSDictionary *)finishReturningInfo;


/**
 *  Stop recording and cancel. Clean up all output and temp files.
 */
-(void)cancel;


@optional
/**
 *  Write a single frame pass as in an image_type
 *
 *  @param image The frame to write as an image_type object.
 *
 *
 *  @return YES if written successfully. NO if error occured during write.
 */
-(void)writeImageTypeFrame:(void *)image;

/**
 *  Write a single frame, passed as a CMSampleBufferRef
 *
 *  @param sampleBuffer The sample buffer of the frame to write.
 *
 *  @return YES if written successfully. NO if error occured during write.
 */
-(void)writePixelBufferFrame:(CMSampleBufferRef)sampleBuffer;


/**
 *  Optional value indicating the path to save the output file (or files) to.
 */
@property (nonatomic) NSURL *outputPathURL;

/**
 *  Optional value indicating the base name of the output file (or files).
 */
@property (nonatomic) NSString *outputFileName;


@end
