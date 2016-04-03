//
//  HFWriterProtocol.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 25/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "HFWObject.h"
#import "HFProcessingProtocol.h"

/**
 *  Protocol for writer objects.
 *  Classes implementing this protocol implement saving a series of frames/images/image data/audio data in buffers
 *  to some file format (to what file format type - video, gif, png sequence, audio etc, is up to the specific implementation)
 */
@protocol HFWriterProtocol <NSObject>

@required
/**
 *  Boolean flag indicating if should work in debug mode.
 */
@property (nonatomic) BOOL debugMode;


/**
 *  YES if needs to include audio information when writing (NO by default).
 */
@property (nonatomic) BOOL includingAudio;

/**
 *  YES if needs to include mask information when writing (YES by default).
 */
@property (nonatomic) BOOL includingAlpha;

/**
 *  YES if when writing the video info, will also include frames dropped from the display (NO by default).
 */
@property (nonatomic) BOOL includingFramesDroppedForDisplay;

/**
 *  The maximum allowed duration. 
 *  If <=0, no maximum duration is set.
 *  If positive, the writer will never continue to write frames after the duration reached.
 */
@property (nonatomic) NSTimeInterval maxDuration;

/**
 *  The absolute output path of the directory all output files will be saved to.
 */
@property (nonatomic) NSString *outputPath;

/**
 *  A randomly generated unique identifier.
 *  It is up to the implementation to decide what to do with this uuid,
 *  but it will be usually used as part of the name of the output files or data.
 */
@property (nonatomic) NSString *uuid;

/**
 *  Info about the saved output file/files.
 */
@property (nonatomic) NSDictionary *outputInfo;

/**
 *  Indicates if prepareWithInfo:formatDescription: was already called for this instance.
 *  NO by default. After prepareWithInfo:formatDescription: will be set to yes.
 */
@property (atomic, readonly) BOOL wasPrepared;

/**
 *  Final initializations, before starting.
 *  must be called before writing the first frame.
 *  If maxDuration, path and uuid not provided before calling this method
 *  default values will be chosen according to the implementation.
 *
 *  @param info NSDictionary extra configuration info (it is up to the implementatin to define what info is possible/required).
 *  @param formatDescription CMFormatDescriptionRef (optional) sample buffer format description. You may pass NULL if implementation doesn't require this.
 *
 *  Calls to this method is ignored if called more than once (ignored if wasPrepared==YES).
 */
-(void)prepareWithInfo:(NSDictionary *)info
     formatDescription:(CMFormatDescriptionRef)formatDescription;

/**
 *  Final initializations, before starting.
 *  must be called before writing the first frame.
 *  If maxDuration, path and uuid not provided before calling this method
 *  default values will be chosen according to the implementation.
 *
 *  @param info NSDictionary extra configuration info (it is up to the implementatin to define what info is possible/required).
 *  @param size The size of the video.
 *
 *  Calls to this method is ignored if called more than once (ignored if wasPrepared==YES).
 */
-(void)prepareWithInfo:(NSDictionary *)info
                  size:(CGSize)size;

/**
 *  Extra info associated with this instance.
 *  Possible to set this using prepareWithInfo:
 *  May be updated internally by the implementation after initialization.
 */
@property (nonatomic, readonly) NSDictionary *info;

/**
 *  Finish up, clean up temp files and resources and close output files as needed.
 */
-(void)finishUp;


/**
 *  Stop writing and cancel. Clean up all output and temp files.
 */
-(void)cancel;

/**
 *  Indicates if a finish condition was met while writing frames.
 *  It is upto the implementation of the writer to decide what that condition is.
 *  (An example for such a condition is if the writer reached the duration limit of the recording)
 *
 *  @return YES if should finish writing. Call finishReturningInfo after that.
 */
-(BOOL)shouldFinish;

@optional
/**
 *  Write a single frame with a corresponding transparency mask.
 *
 *  The frame and mask data is provided as UIImage objects.
 *
 *  @param frame UIImage the frame to write.
 *  @param mask  UIImage the corresponding transparency mask for that frame.
 *  @param timeStamp the time stamp of this frame in nano seconds
 *  @param error NSError out error
 *
 *  @discussion
 *  It is the responsibility of the caller to manage on what thread and in what priority to dispatch this work.
 */
-(void)writeFrame:(UIImage *)frame
             mask:(UIImage *)mask
        timeStamp:(long long)timeStamp
            error:(NSError **)error;


/**
 *  Write audio buffer to audio output.
 *
 *  @param buffer    Audio buffer to write.
 *  @param timeStamp long long the time stamp related to this buffer.
 *  @param error NSError out error
 */
-(void)writeAudioBuffer:(CMSampleBufferRef)buffer
              timeStamp:(long long)timeStamp
                  error:(NSError **)error;


@end
