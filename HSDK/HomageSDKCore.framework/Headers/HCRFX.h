//
//  HCRFX.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 16/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCRObject.h"

@class HCSourceLayer;

/**
 *  Base effects configuration object
 */
@interface HCRFX : HCRObject

#pragma mark - Factory
/**
 *  Returns a dictionary of supported effect types.
 *  The key is the name of the effect.
 *  The value is a dictinary with info about the effect.
 *  @"effect_type":{
 *                  "kf_animation_supported":@YES/@NO,
 *                  "description":"..."
 *                 }
 *
 *  @return NSDictionary with info about supported effects.
 */
+(NSDictionary *)supportedEffectTypes;

/**
 *  Creates a new effect wrapper configured according to provided CFG and related layer info.
 *
 *  @param cfg   NSDictionary with the configuration of the effect.
 *  @param layer related HCSourceLayer providing more info about the layer.
 *
 *  @return HCRFX effect wrapper.
 */
+(HCRFX *)effectWithCFG:(NSDictionary *)cfg layer:(HCSourceLayer *)layer;

#pragma mark - Configuration
/**
 *  YES if the effect is enabled.
 */
@property (nonatomic) BOOL enabled;

/**
 *  The effect type name as NSString
 */
@property (nonatomic, readwrite) NSString *effectType;


/**
 *  Weak pointer to the related layer.
 */
@property (nonatomic, readonly, weak) HCSourceLayer *layer;

/**
 *  The cfg of the effect.
 */
@property (nonatomic, readonly) NSDictionary *cfg;

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
 *  A black&white filter effect.
 */
extern NSString* const hcrEffectTypeGrayScale;

/**
 *  mask
 *  A mask effect.
 *  (using any source - so the mask can be a single frame/static mask or a dynamic mask, depending on the source)
 */
extern NSString* const hcrEffectTypeMask;

/**
 *  image_mask
 *  A single image/frame static mask effect.
 *  (soon to be deprecated - @see mask)
 */
extern NSString* const hcrEffectTypeImageMask;

/**
 *  gif_mask
 *  A dynamic gif mask effect.
 *  (soon to be deprecated - @see mask)
 */
extern NSString* const hcrEffectTypeGifMask;


/**
 *  sepia
 *  A sepia filter effect.
 */
extern NSString* const hcrEffectTypeSepia;

/**
 *  cartoon
 *  A cartoonize filter effect.
 */
extern NSString* const hcrEffectTypeCartoon;

/**
 *  alpha
 *  An alpha (transparency) effect.
 */
extern NSString* const hcrEffectTypeAlpha;

/**
 *  Init an effect with provided effect CFG (and a weak pointer to the related layer for more info).
 *
 *  @param cfg NSDictionary the configuration for the effect.
 *  @param layer HCSourceLayer related layer object.
 *
 *  @return HCRFX (an instance of a specific effect wrapper that is a derived class of HCRFX)
 */
-(HCRFX *)initWithCFG:(NSDictionary *)cfg layer:(HCSourceLayer *)layer;

/**
 *  Set the CFG of the effect, after instantiation.
 *
 *  @param cfg NSDictionary with the effect configuration.
 */
-(void)setCFG:(NSDictionary *)cfg;

/**
 *  Parse the CFG provided on initWithCFG.
 *  Already called on initWithCFG
 */
-(void)parseCFG;

#pragma mark - FPS & Duration
/**
 *  The duration of the effect as NSTimeInterval (uses the related layer setting by default)
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 *  The fps of the effect NSInteger (uses the fps of the related layer by default)
 */
@property (nonatomic, readonly) NSInteger fps;

/**
 *  Set the duration and fps of the effect.
 *
 *  @param duration NSTimeInterval duration of the effect in seconds.
 *  @param fps      NSInteger FPS of the effect.
 */
-(void)setDuration:(NSTimeInterval)duration fps:(NSInteger)fps;

#pragma mark - CV Effect
/**
 *  Uses this effect wrapper configuration to create the CV Effect.
 *
 *  @return CHrEffectI CV effect configured by this effect wrapper.
 */
-(void *)createCVEffect;

@end
