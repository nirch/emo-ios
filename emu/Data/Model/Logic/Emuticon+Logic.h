//
//  EmuticonDef+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_EMU @"Emuticon"

#import "Emuticon.h"

@interface Emuticon (Logic)

/**
 *  Finds emuticon object with the provided oid.
 *
 *  @param oid     The id of the object
 *  @param context The managed object context if exists. nil if doesn't exist.
 */
+(Emuticon *)findWithID:(NSString *)oid
                context:(NSManagedObjectContext *)context;

/**
 *  Create or update a preview emuticon object.
 *
 *  @param oid            The oid of the newly created preview emuticon object.
 *  @param footageOID     The user footage used to render this emuticon (must exist for creation)
 *  @param emuticonDefOID The emuticon definition used to render this emuticon (must exist for creation).
 *  @param context        The managed object context.
 *
 *  @return An emuticon object flagged as preview, if successful. 
 *          Will return nil if failed to create.
 */
+(Emuticon *)previewWithOID:(NSString *)oid
                 footageOID:(NSString *)footageOID
             emuticonDefOID:(NSString *)emuticonDefOID
                    context:(NSManagedObjectContext *)context;


/**
 *  The url to the animated gif rendered for this emuticon object.
 *
 *  @return NSURL pointing to the rendered animated gif.
 */
-(NSURL *)animatedGifURL;

@end
