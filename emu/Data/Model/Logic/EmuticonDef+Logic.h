//
//  EmuticonDef+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_EMU_DEF @"EmuticonDef"

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
 *  Create an emuticon for the emuticon definition.
 *
 *  @return Emuticon object.
 */
-(Emuticon *)spawn;

/**
 *  An array of all related emuticons
 *  excluding preview emuticons.
 *
 *  @return An array of none preview emuticons
 */
-(NSArray *)nonPreviewEmuticons;



-(NSString *)pathForUserLayerMask;
-(NSString *)pathForBackLayer;
-(NSString *)pathForFrontLayer;
-(BOOL)allResourcesAvailable;
-(BOOL)isMissingResourceNamed:(NSString *)resourceName;
-(void)removeAllResources;

@end
