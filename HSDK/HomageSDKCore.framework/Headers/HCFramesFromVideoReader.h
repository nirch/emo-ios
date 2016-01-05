//
//  HCFramesFromVideoReader.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 13/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class UIImage;

/**
 *  Helper class for reading a series of frames from a video file.
 */
@interface HCFramesFromVideoReader : NSObject

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
 */

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

@end
