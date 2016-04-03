//
//  HCVideoFromFramesWriter.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 11/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@class UIImage;

/**
 *  Helper class for writing a video file from a series of frames
 *  Each frame should be provided with a corresponding time stamp.
 *  Time stamps should be provided as long long values 
 *  units scale of the time stamp is 1/1000000000th of a second.
 */
@interface HCVideoFromFramesWriter : NSObject

/**
 *  YES, if done writing and closed the file.
 */
@property (atomic) BOOL done;

/**
 *  Set up the asset writer stack.
 *
 *  @param size         CGSize The size of the frames to write
 *  @param bitsPerPixel float bitPerPixel (compression settings)
 *  @param videoURL     NSURL The video url
 *  @param outError     NSError out error
 */
-(void)setupWithSize:(CGSize)size
        bitsPerPixel:(float)bitsPerPixel
            videoURL:(NSURL *)videoURL
               error:(NSError **)outError;

/**
 *  Write an image frame to the movie file using the provided time stamp.
 *
 *  @param image     UIImage image to write.
 *  @param timeStamp long long timeStamp in 1/1000000000th second units.
 *  @param error     NSError raised error if encountered.
 */
-(void)writeImage:(UIImage *)image
        timeStamp:(long long)timeStamp
            error:(NSError **)error;

/**
 *  Raise a flag that should finish writing when the next frame is received.
 *  When actually finished writing and closing the file
 *  the done property will be set to YES.
 *  This method just raises a flag. Writing will not finish if no more frames
 *  are attempted to be written.
 */
-(void)markAsNeedsToFinish;

/**
 *  Finish up and close all files.
 *  This method is blocking. Don't call it on the main thread
 *  (you shouldn't be creating the video on the main thread anyway!)
 */
-(void)finishUp;

/**
 *  Cancel the asset writer session.
 */
-(void)cancel;


/**
 *  Add an audio file at given url that will be stitched as an audio track
 *  after the video render is ready.
 *
 *  @param audioURL The file url of an audio file.
 */
-(void)addAudioTrackFromURL:(NSURL *)audioURL;

@end
