//
//  Feature+Logic.h
//  emu
//
//  Created by Aviv Wolf on 18/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#define E_FEATURE @"Feature"

#define FEATURE_EMU_PRO @"Emu pro"
#define FEATURE_BLOCK_ADS @"Block ads"
#define FEATURE_REMOVE_WATERMARKS @"Remove watermarks"
#define FEATURE_ALLOW_SAVE_AND_COPY @"Allow save and copy"

#import "Feature.h"

@interface Feature (Logic)

#pragma mark - Find or create
/**
 *  Finds or creates a feature object with the provided oid.
 *
 *  @param oid     The feature internal id / name.
 *  @param context The managed object context.
 *
 *  @return EmuticonDef object.
 */
+(Feature *)findOrCreateWithOID:(NSString *)oid
                        context:(NSManagedObjectContext *)context;


/**
 *  Finds feature object with the provided oid.
 *
 *  @param oid     The id of the object (same as product id used in itunes connect)
 *  @param context The managed object context if exists. nil if doesn't exist.
 *
 *  @return Feature (or nil if not found)
 */
+(Feature *)findWithOID:(NSString *)oid
                context:(NSManagedObjectContext *)context;


/**
 *  Finds feature object with the provided product identifier.
 *
 *  @param pid     product identifier used in itunes connect
 *  @param context The managed object context if exists. nil if doesn't exist.
 *
 *  @return Feature (or nil if not found)
 */
+(Feature *)findWithPID:(NSString *)pid
                context:(NSManagedObjectContext *)context;


#pragma mark - Purchased features

/**
 *  Returns YES if a feature with provided oid was purchased.
 *
 *  @param oid The oid if the feature
 *  @param context The managed object context if exists. nil if doesn't exist.
 *
 *  @return YES if feature found and was purchased. NO otherwise.
 */
+(BOOL)wasFeaturePurchased:(NSString *)oid context:(NSManagedObjectContext *)context;

/**
 *  Returns YES if this feature was unlocked.
 *  A feature is unlocked if it was purchased or if the user purchased Emu Pro.
 *
 *  @return YES if unlocked.
 */
-(BOOL)wasUnlocked;

#pragma mark - Helper methods.
/**
 *  Helper methods for checking if specific features are unlocked or not.
 */

/**
 *  Returns YES if emu pro is unlocked. 
 *  The following features will also return YES if emu pro is unlocked:
 *    - Block ads
 *    - Remove watermarks
 *    - Allow save and copy
 *
 *  @param context The managed object context if exists. nil if doesn't exist.
 *
 *  @return YES if emu pro is unlocked.
 */
+(BOOL)isEmuProUnlockedInContext:(NSManagedObjectContext *)context;

// Other features (these features are also considered unlocked if emu pro is unlocked).
+(BOOL)isBlockAdsUnlockedInContext:(NSManagedObjectContext *)context;
+(BOOL)isRemoveWatermarksUnlockedInContext:(NSManagedObjectContext *)context;
+(BOOL)isAllowSaveAndCopyUnlockedInContext:(NSManagedObjectContext *)context;

@end
