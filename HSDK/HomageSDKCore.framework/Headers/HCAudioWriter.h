//
//  HCAudioWriter.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 11/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 *  Helper class for writing a video file from a series of frames
 *  Each frame should be provided with a corresponding time stamp.
 *  Time stamps should be provided as long long values 
 *  units scale of the time stamp is 1/1000000000th of a second.
 */
@interface HCAudioWriter : NSObject

/**
 *  YES, if done writing and closed the file.
 */
@property (atomic) BOOL done;

/**
 *  Set up the asset writer stack.
 *
 *  @param audioURL   NSURL The audio url
 *  @param sampleRate The sample rate of the output.
 *  @param outError   NSError out error
 */
-(void)setupAudioURL:(NSURL *)audioURL
          sampleRate:(double)sampleRate
               error:(NSError **)outError;

/**
 *  Write a buffer to the audio file using the provided time stamp.
 *
 *  @param buffer    Audio buffer to write
 *  @param timeStamp The time stamp
 *  @param error     NSError out error
 */
-(void)writeAudioBuffer:(CMSampleBufferRef)buffer
              timeStamp:(long long)timeStamp
                  error:(NSError **)error;

/**
 *  Raise a flag that should finish writing when the next buffer is received.
 *  When actually finished writing and closing the file
 *  the done property will be set to YES.
 *  This method just raises a flag. Writing will not finish if no more buffers
 *  are attempted to be written.
 */
-(void)markAsNeedsToFinish;

/**
 *  Finish up and close all files.
 *  This method is blocking. Don't call it on the main thread
 *  (you shouldn't be creating the audio file on the main thread anyway!)
 */
-(void)finishUp;

/**
 *  Cancel the asset writer session.
 */
-(void)cancel;

@end
