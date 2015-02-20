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
 */
+(EmuticonDef *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context;

@end
