//
//  HCRFXTransform.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 21/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//
#import <CoreGraphics/CoreGraphics.h>

#import "HCRFXAnimated.h"

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
 *  Transform effect (scale 0.0-1.0, translation [X,Y], rotate [X,Y,Z]
 *  Also supports keyframe animations / tweening.
 */
@interface HCRFXTransform : HCRFXAnimated

/**
 *  Used when setting a single (not animated) value for the transform effect.
 */
extern NSString* const hcrTransformValue;

/**
 *  Position units.
 */
extern NSString* const hcrPositionUnits;

/**
 *  Position units are points/pixels
 */
extern NSString* const hcrPositionUnitsPoints;

/**
 *  Position units are normalized (
 *
 *  For example:
 *    [0,0] top left corner
 *    [0.5,0.5] center
 *    [1,1] bottom right corner
 */
extern NSString* const hcrPositionUnitsNormalized;


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
 *  Space scale X.
 *  Scales the space.
 *  A multiplier that will be applied to all positioning values on the X axis.
 *  This is an optional value and is set to 1.0 by default.
 *  In most cases, you shouldn't use this value.
 *  (available for backward support of data available in some older databases/apps)
 */
@property (nonatomic) CGFloat scaledSpaceX;


/**
 *  Space scale Y.
 *  Scales the space.
 *  A multiplier that will be applied to all positioning values on the Y axis.
 *  This is an optional value and is set to 1.0 by default.
 *  In most cases, you shouldn't use this value.
 *  (available for backward support of data available in some older databases/apps)
 */
@property (nonatomic) CGFloat scaledSpaceY;


/**
 *  The position units the position data in the CFG is provided in.
 *  The info in the CFG will be converted and stored as normalized units.
 */
@property (nonatomic, readonly) fxPositionUnits positionUnits;

#pragma mark - Initialization
/**  @name Initialization */

/**
 *  Initialize transform effect configuration for a provided space.
 *
 *  @param spaceSize The size of the 2 dimensional space.
 *
 *  @return HCTransformFX transform effect configuration object.
 */
-(instancetype)initForSpaceSize:(CGSize)spaceSize;

# pragma mark - Keyframes
/**  @name Setting / Adding / Removing keyframes */

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
 *  Sets the initial transform (position, scale, rotation).
 *  Equivalent to setting transform key frame at time 0
 *
 *  @param pos   Normalized x,y position.
 *  @param scale Normalized scale value.
 *  @param rot   HCRotation 3-tuple rotation on x, y and z axis.
 */
-(void)setPos:(CGPoint)pos
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

#pragma mark - Position info
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

@end
