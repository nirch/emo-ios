//
//  EmuticonDef+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_EMU_DEF @"EmuticonDef"

#define EMU_DEFAULT_WIDTH 240
#define EMU_DEFAULT_HEIGHT 240

#import "EmuticonDef.h"

@interface EmuticonDef (Logic)

#pragma mark - Find or create
/**
 *  Finds or creates a emuticon definition object with the provided oid.
 *
 *  @param oid     The id of the object.
 *  @param context The managed object context.
 *
 *  @return EmuticonDef object.
 */
+(EmuticonDef *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context;


/**
 *  Finds emuticon definition object with the provided oid.
 *
 *  @param oid     The id of the object
 *  @param context The managed object context if exists. nil if doesn't exist.
 */
+(EmuticonDef *)findWithID:(NSString *)oid
                   context:(NSManagedObjectContext *)context;


/**
 *  Given a list of emu defs, spawns emuticon objects for those emu defs.
 *
 *  @param emuDefs An array of emu defs.
 *
 *  @return An array of spawned emuticons.
 */
+(NSArray *)createMissingEmuticonsForEmuDefs:(NSArray *)emuDefs;


/**
 *  Create an emuticon for the emuticon definition.
 *
 *  @return Emuticon object.
 */
-(Emuticon *)spawn;

/**
 *  The aspect ratio of the emu (1.0f if square, ~1.777 for 16/9 etc)
 *
 *  @return CGFloat of the width divided by height.
 */
-(CGFloat)aspectRatio;

/**
 *  An array of all related emuticons
 *  excluding preview emuticons.
 *
 *  @return An array of none preview emuticons
 */
-(NSArray *)nonPreviewEmuticons;

#pragma mark - Resources Paths
-(NSString *)pathForUserLayerMask;
-(NSString *)pathForUserLayerMaskInHD:(BOOL)inHD;

-(NSString *)pathForUserLayerDynamicMask;
-(NSString *)pathForUserLayerDynamicMaskInHD:(BOOL)inHD;

-(NSString *)pathForBackLayer;
-(NSString *)pathForBackLayerInHD:(BOOL)inHD;

-(NSString *)pathForFrontLayer;
-(NSString *)pathForFrontLayerInHD:(BOOL)inHD;

#pragma mark - Resources required
-(NSInteger)requiredResourcesCount;
-(NSInteger)requiredResourcesCountInHD:(BOOL)inHD;

-(BOOL)allResourcesAvailable;
-(BOOL)allResourcesAvailableInHD:(BOOL)inHD;

-(NSArray *)allMissingResourcesNames;
-(NSArray *)allMissingResourcesNamesInHD:(BOOL)inHD;

-(BOOL)isMissingResourceNamed:(NSString *)resourceName;

#pragma mark - Removing resources
-(void)removeAllResources;
-(void)removeAllHDResources;

@end
