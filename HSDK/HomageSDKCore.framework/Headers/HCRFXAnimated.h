//
//  HCRFXAnimated.h
//  HomageSDKCore
//
//  Base class for all effects supporting key frame animation.
//  Don't create instances of the HCRFXAnimated class. Create instances only of the derived classes.
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import "HCRFX.h"

#define KF_ID @0

/**
 *  The time unit used in animation key frames.
 */
typedef NS_ENUM(NSInteger, fxTimeUnits) {
    /**
     *  Time unit given as a frame number.
     */
    fxTimeUnitsUndefined   = -1,
    /**
     *  Time unit given as a frame number.
     */
    fxTimeUnitsFrames      = 100,
    /**
     *  Time unit given in seconds (fractions allowed)
     */
    fxTimeUnitsSeconds     = 200,
    /**
     *  Time unit given as a normalized value in the range 0.0-1.0
     *  0.0 - The beginning of the duration
     *  1.0 - The end of the duration
     */
    fxTimeUnitsNormalizedTime = 300
};

/**
 *  Base class for effect wrappers that also support key frame animations / tweening.
 */
@interface HCRFXAnimated : HCRFX

/**
 *  Time (
 */
extern NSString* const hcrTime;

/**
 *  Frame number.
 *  Deprecated
 *  (exists for historical reasons. You can pass frame number using hcrTime if hcrTimeUnitsFrames is used)
 */
extern NSString* const hcrFrame;

/**
 *  Determines in what time units animation info is provided in.
 *
 *  Possible values:
 *      frames - time is provided as a count of frames
 *      seconds - time is provided as a time interval in seconds (fractions supported)
 *      normalized - time is provided as a value between 0.0-1.0 where 0.0 is the beginning of the output duration and 1.0 is the end of the duration.
 */
extern NSString* const hcrTimeUnits;
extern NSString* const hcrTimeUnitsFrames;
extern NSString* const hcrTimeUnitsSeconds;
extern NSString* const hcrTimeUnitsNormalizedTime;

/**
 *  Animation - key frames animation info.
 */
extern NSString* const hcrAnimation;

#pragma mark - Time & Animation
/**
 *  The time units used when providing timeline information.
 */
@property (nonatomic) fxTimeUnits timeUnits;

/**
 *  Converts a value of normalized time 0.0-1.0 to a frame number
 *  based on the duration + fps set for this effect.
 *
 *  @param normalizedTime A value in the range 0.0-1.0
 *
 *  @return NSInteger of a frame number.
 */
-(NSInteger)frameForNormalizedTime:(double)normalizedTime;

/**
 *  Converts NSNumber to a long long time stamp in nano seconds.
 *  Converts based on the currently set time units.
 *
 *  @param timeNumber NSNumber with timing info.
 *
 *  @return long long Time Stamp in nano seconds.
 */
-(long long)parsedTimeStamp:(NSNumber *)timeNumber;

# pragma mark - Parsing the animation

/**
 *  If key frame animation is defined in the configuration,
 *  iterates
 */
-(void)parseAnimation;

/**
 *  Parse a single key frame from the animation configuration.
 *  This is a virtual method and must be implemented in the derived animated effect.
 *
 *  @param keyFrame The keyframe information to be parsed.
 */
-(void)parseKeyFrame:(NSDictionary *)keyFrame;

/**
 *  Parses the frame number from the key frame info.
 *
 *  @param kf NSDictionary with the key frame info.
 *
 *  @return NSInteger with the key frame number.
 */
-(NSInteger)parseFrame:(NSDictionary *)kf;


# pragma mark - Keyframes
/**  @name Setting / Adding / Removing keyframes */

/**
 *  The stored key frames of the animated effect.
 */
@property (nonatomic, readonly) NSMutableDictionary *keyFrames;

/**
 *  Virtual method. Must be implemented in the derived class.
 *
 *  @param tuple A tuple with the info for a key frame.
 */
-(void)setKeyFrameWithTuple:(NSArray *)tuple;

/**
 *  An ordered list of all the keyframes set on this effect.
 *
 *  @return NSArray of ordered NSNumber of the key frame indexes.
 */
-(NSArray *)orderedKeyFrames;

/**
 *  The raw data stored for a given key frame at index.
 *
 *  @param keyFrame NSInteger the key frame index.
 *
 *  @return NSDictionary if keyframe exists at index or nil if it doesn't.
 */
-(NSDictionary *)dataForKeyFrame:(NSInteger)keyFrame;

/**
 *  Indication if a key frame exists in given index.
 *
 *  @param keyFrame NSInteger key frame index.
 *
 *  @return YES/true if a key frame exists in provided index.
 */
-(BOOL)hasKeyFrame:(NSInteger)keyFrame;

#pragma mark - String Serialization (TF)
/**  @name String Serialization (TF) */

/**
 *  Returns a string representation of data of a given frame.
 *
 *  @param keyFrame NSInteger the key frame index.
 *
 *  @return A string representation of the data for the key frame. nil if keyframe doesn't exist.
 */
-(NSString *)stringForKeyFrame:(NSInteger)keyFrame;


/**
 *  A string representation of the effect (all key frames)
 *
 *  @return NSString representing all info for all key frames in set coordinates space.
 */
-(NSString *)stringForAllFrames;



@end
