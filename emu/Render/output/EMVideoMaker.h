//
//  EMVideoMaker.h
//  emu
//
//  Created by Aviv Wolf on 5/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "HrRendererLib/HrOutput/HrOutputI.h"


@interface EMVideoMaker : NSObject

#pragma mark - Basic configurations
//
// Video maker basic configuration
//
@property CMVideoDimensions dimensions;
@property float bitsPerPixel;
@property NSURL *videoOutputURL;
@property NSInteger fps;

#pragma mark - Streamed writing
/**
 steamedWriting - YES if writes video frame by frame as each frame is received (default)
                  NO if stores all frames in memory before starting to write the video.

 =-=-=-=-
 Warning:
 =-=-=-=-
 If streamed writing is turned off (on by default)
 make sure the source video is short with just a few frames (under about 50)
 becaues all frames are stored in memory while writing the video.
 Will be turned off when some effects are used (like writing video in a loop, for example).
*/
@property (nonatomic, readonly) BOOL steamedWriting;


#pragma mark - Video output effects
/**
 fxLoops
 By default (fxLoops<=1) will just write the frames normally.
 If fxLoops>=2 will write a video with all the frames in a loop fxLoops times.
 
 (Warning: when used, sets streamed writing to NO. Check warning under streamed writing property)
*/
@property (nonatomic) NSInteger fxLoops;

/**
 fxPingPong
 By default (fxPingPong=NO) loops will cycle frames from start to finish.
 If set to YES will alternate playing the video from start to finish and in reverse in each loop.
 This effect will have no effect (HA!) if fxLoops is not set/used.
 */
@property (nonatomic) BOOL fxPingPong;


#pragma mark - Audio
@property (nonatomic) NSURL *audioFileURL;
@property (nonatomic) NSTimeInterval audioStartTime;


#pragma mark - Adding frames

/**
    Expects an image_type (image3 with three RGB channels).
    If streamed write set to YES, will write the frames as received.
    If streamed write set to NO, will store in memory all frames and write only when finishing up.
 */
-(void)addImageFrame:(image_type *)image;

#pragma mark - Finishing up
-(void)finishUp;

@end
