//
//  HCTransformFX.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 18/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "HCRFX.h"

/**
 *  Rotation on x, y and z axis.
 */
struct HCRotation {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};
typedef struct HCRotation HCRotation;


/**
 *  The time unit used in animation key frames.
 */
typedef NS_ENUM(NSInteger, fxPositionUnits) {
    /**
     *  Position units in space provided as points in space 
     *  (0,0) - Top left corner
     *  (width, height) - Bottom right corner
     */
    fxPositionUnitsPoints      = 100,
    /**
     *  Position units in space provided as normalized values in space
     *  (0.0,0.0) - Top left corner
     *  (1.0,1.0) - Bottom right corner
     */
    fxPositionUnitsNormalized     = 200,
};


/**
 *  A helper class for configuring a transform effect for an HCSourceLayer
 */
@interface HCRFXTransform : HCRFX

/**
 *  Position units.
 */
extern NSString* const hcrPositionUnits;

/**
 *  Position.
 */
extern NSString* const hcrPosition;

/**
 *  Scale.
 */
extern NSString* const hcrScale;

/**
 *  Rotate.
 */
extern NSString* const hcrRotate;


/**
 *  Space scale X.
 *  Scales the space.
 *  A multiplier that will be applied to all positioning values on the X axis.
 *  This is an optional value and is set to 1.0 by default.
 *  In most cases, you shouldn't use this value.
 *  (available for backward support of data available in some older databases/apps)
 */
extern NSString* const hcrSpaceScaleX;

/**
 *  Space scale Y.
 *  Scales the space.
 *  A multiplier that will be applied to all positioning values on the Y axis.
 *  This is an optional value and is set to 1.0 by default.
 *  In most cases, you shouldn't use this value.
 *  (available for backward support of data available in some older databases/apps)
 */
extern NSString* const hcrSpaceScaleY;


/**
 *  The space coordinate size for this transform effect.
 *  Can be set only on initialization.
 *  This coordinate space size is used to translate normalized coordinates
 *  to exact positions in pixels/points etc.
 */
@property (nonatomic, readonly) CGSize spaceSize;

/**
 *  The position units the position data in the CFG is provided in.
 *  The info in the CFG will be converted and stored as normalized units.
 */
@property (nonatomic, readonly) fxPositionUnits positionUnits;

/**  @name Initialization */

/**
 *  Initialize transform effect configuration for a provided space.
 *
 *  @param spaceSize The size of the 2 dimensional space.
 *
 *  @return HCTransformFX transform effect configuration object.
 */
-(instancetype)initForSpaceSize:(CGSize)spaceSize;

/**
 *  Initialize transform effect configuration for a provided space and configuration info.
 *
 *  @param spaceSize The size of the 2 dimensional space.
 *  @param cfg       NSDictionary with all required configuration info.
 *  @param duration  NSTimeInterval the duration of the effect
 *  @param fps       Frames per second
 *
 *  @return New instance of the HCRFXTransform effect configuration object.
 */
-(instancetype)initForSpaceSize:(CGSize)spaceSize
                            cfg:(NSDictionary *)cfg
                       duration:(NSTimeInterval)duration
                            fps:(NSInteger)fps;


/**  @name Setting / Removing keyframes */

/**
 *  Sets (or updates) a keyframe at a given index.
 *  The transform effect will add the values in between keyframes
 *  when creating the animation.
 *  For each key frame all parameters must be defined:
 *  position (normalized)
 *
 *  @param frame The index number of the keyframe.
 *  @param pos   Normalized x,y position. 
 *      0.0,0.0 is for top left position in current space
 *      1.0,1.0 is for bottom right position in current space
 *  @param scale Normalized scale value.
 *  @param rot   HCRotation 3-tuple rotation on x, y and z axis.
 */
-(void)setKeyFrame:(NSInteger)frame
               pos:(CGPoint)pos
             scale:(CGFloat)scale
               rot:(HCRotation)rot;

/**
 *  Same as setKeyFrame:pos:scale:rot:
 *  but information is provided as a 7 tuple.
 *   0 - NSInteger frame number
 *   1 - CGFloat position x (normalized)
 *   2 - CGFloat position y (normalized)
 *   3 - CGFloat scale
 *   4 - CGFloat rotation x
 *   5 - CGFloat rotation y
 *   6 - CGFloat rotation z
 *
 *  @param tuple NSArray with 7
 */
-(void)setKeyFrameWithTuple:(NSArray *)tuple;

/**
 *  Remove a keyframe in a given frame index.
 *  If frame doesn't exist, will just ignore the call (no error raised).
 *
 *  @param frame NSInteger - The index number of the key frame.
 */
-(void)removeKeyFrame:(NSInteger)frame;

/**  @name Getting info */

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


/**
 *  The normalized positioning (coordinated 0,0 top left 1,1 bottom right)
 *  set for this key frame.
 *
 *  @note: Ensure the keyframe actually exists using hasKeyFrame: before calling this method.
 *
 *  @param keyFrame NSInteger key frame index.
 *
 *  @return Normalized positioning coordinated. (0,0) top left. (1,1) bottom right.
 */
-(CGPoint)positionNormalizedForKeyFrame:(NSInteger)keyFrame;

/**
 *  Converts the stored normalized position set for a keyframe to the coordinates in defined 2D space.
 *
 *  @note: 1) Returned values are always whole numbers.
 *  @note: 2) Make sure the keyframe actually exists before calling this method.
 *
 *  @param keyFrame NSInteger the key frame index.
 *
 *  @return CGPoint of the position in the provided 2D space (space size determind on instantiation).
 */
-(CGPoint)positionForKeyFrame:(NSInteger)keyFrame;


/**
 *  Converts the stored normalized position set for a keyframe to the coordinates in defined 2D space.
 *
 *  @note: 1) Returned values are always whole numbers.
 *  @note: 2) Ensure the keyframe actually exists before calling this method.
 *
 *  @param keyFrame NSInteger the key frame index.
 *  @param scaledSpace CGFloat a multiplier for stertching/shrinking the 2D coordinate space.
 *
 *  @return CGPoint of the position in the provided 2D space (space size determind on instantiation).
 */
-(CGPoint)positionForKeyFrame:(NSInteger)keyFrame scaledSpace:(CGFloat)scaledSpace;

/**  @name Serialization */

/**
 *  Returns a string representation of data of a given frame.
 *  Position values will be returned in space coordinates (depending on 2D space size
 *
 *  @param keyFrame NSInteger the key frame index.
 *  @param scaledSpace CGFloat a multiplier for stertching/shrinking the 2D coordinate space.
 *
 *  @return A string representation of the data for the key frame. nil if keyframe doesn't exist.
 */
-(NSString *)stringForKeyFrame:(NSInteger)keyFrame
                   scaledSpace:(CGFloat)scaledSpace;

/**
 *  Returns a string representation of data of a given frame.
 *  Position values will be returned in space coordinates (depending on 2D space size
 *
 *  @param keyFrame NSInteger the key frame index.
 *
 *  @return A string representation of the data for the key frame. nil if keyframe doesn't exist.
 */
-(NSString *)stringForKeyFrame:(NSInteger)keyFrame;


/**
 *  A string representation of the effect (all key frames)
 *  Positioning is translated from store normalized position to defined coordinate space.
 *
 *  @return NSString representing all info for all key frames in set coordinates space.
 */
-(NSString *)stringForAllFrames;

/**
 *  A string representation of the effect (all key frames)
 *  Positioning is translated from store normalized position to defined coordinate space.
 *
 *  @param scaledSpace CGFloat a multiplier for stertching/shrinking the 2D coordinate space.
 *
 *  @return NSString representing all info for all key frames in set coordinates space.
 */
-(NSString *)stringForAllFramesInScaledSpace:(CGFloat)scaledSpace;


@end
