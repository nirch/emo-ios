//
//  HCFramesFromVideoReader.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 13/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

/**
 *  VideoFramesEnumeratorBlock
 *
 *  @param iFrame    The number of the frame index (starts with 0)
 *  @param frame     UIImage current frame
 *  @param timeStamp long long the time stamp of the current frame.
 *  @param error     NSError error while reading frames from the video file.
 */
typedef void (^VideoFramesEnumeratorBlock)(NSInteger iFrame, UIImage *frame, long long timeStamp, NSError *error);

/**
 *  Helper class for reading a series of frames from a video file.
 */
@interface HCFramesFromVideoReader : NSObject

/**
 *  Flag that is raised when there are no more frames to read from the video file.
 */
@property (nonatomic, readonly) BOOL finishedReadingFromFile;

/**
 *  The time stamp of the latest frame read.
 */
@property (nonatomic, readonly) long long latestFrameTimeStamp;

/**
*  Set up the asset reader stack.
*
*  @param size     CGSize the size of the frames
*  @param videoURL NSURL the url of the video
*  @param outError NSError out error
*/
-(void)setupWithSize:(CGSize)size
            videoURL:(NSURL *)videoURL
               error:(NSError **)outError;

/**
 *  Set up the asset reader stack.
 *
 *  @param size     CGSize the size of the frames
 *  @param videoURL NSURL the url of the video
 *  @param range    The CMTimeRange that will be set on asset reader, before starting to read.
 *  @param outError NSError out error
 */
-(void)setupWithSize:(CGSize)size
            videoURL:(NSURL *)videoURL
               range:(CMTimeRange)range
               error:(NSError **)outError;


/**
 *  Read next image frame after timestamp.
 *  When calling this method, the timestamp can only be increased.
 *  If you pass a timestamp that is smaller than a timestamp in a previous call
 *  an error will be returned.
 *
 *  @param timeStamp long long A time in 100000000th of a second. The returned frame should be equal or later than this time stamp.
 *  @param outError  NSError out error.
 *
 *  @return UIImage of the frame read from the video at provided time stamp.
 */
-(UIImage *)readImageAtTimeStamp:(long long)timeStamp
                           error:(NSError **)outError;



/**
 *  Read next image frame.
 *
 *  @param outError  NSError out error.
 *
 *  @return UIImage of the next frame read from the video.
 */
-(UIImage *)readImageOfNextFrame:(NSError **)outError;

/**
 *  Enumerates all frames in the file one bye one with an enumeration block.
 *  The block will receive the frames as UIImage objects and a long long time stamp in MSEC
 *
 *  @param enumeratorBlock VideoFramesEnumeratorBlock
 */
-(void)enumerateFrames:(VideoFramesEnumeratorBlock)enumeratorBlock;

/**
 *  Seek back to the beginning of the video.
 *  Will set finishedReadingFromFile to NO.
 */
-(void)restart;

@end
