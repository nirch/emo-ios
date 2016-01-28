//
//  HCRFX.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 16/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCRObject.h"

#define NANO_SECS_N 1000000000

@class HCRender;

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
 *  Base effects configuration object
 */
@interface HCRFX : HCRObject

/**
 *  Effect type.
 */
extern NSString* const hcrEffectType;

/**
 *  transform
 *  Transform effect.
 *  Key frame animations of position, rotation and scale.
 *  See HCRFXTransform for more details.
 */
extern NSString* const hcrEffectTypeTransform;

/**
 *  gray_scale
 *  A boolean flag for gray scale effect.
 *  If value is true, converts the layer to gray scale.
 */
extern NSString* const hcrEffectTypeGrayScale;

/**
 *  mask
 *  A mask effect.
 */
extern NSString* const hcrEffectTypeMask;

/**
 *  dmask
 *  A dynamic mask effect.
 */
extern NSString* const hcrEffectTypeDMask;

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

/**
 *  Returns an array of supported effect types.
 *
 *  @return NSArray if NSString with names of the supported effect types.
 */
-(NSArray *)supportedEffectTypes;

/**
 *  Frames per second (12 by default)
 */
@property (nonatomic, readonly) NSInteger fps;

/**
 *  Duration in seconds. Fractions allowed. (2.0 seconds by default)
 */
@property (nonatomic, readonly) NSTimeInterval duration;

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
 *  Set the duration and fps of the effect.
 *
 *  @param duration NSTimeInter
 *  @param fps      Frames per second
 */
-(void)setDuration:(NSTimeInterval)duration fps:(NSInteger)fps;

/**
 *  Parse the time units that should be used.
 *
 *  @param cfg NSDictionary configuration info
 */
-(void)parseTimeUnits:(NSDictionary *)cfg;

/**
 *  Converts NSNumber to a long long time stamp in nano seconds.
 *  Converts based on the currently set time units.
 *
 *  @param timeNumber NSNumber with timing info.
 *
 *  @return long long Time Stamp in nano seconds.
 */
-(long long)parsedTimeStamp:(NSNumber *)timeNumber;


@end
