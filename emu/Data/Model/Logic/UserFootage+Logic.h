//
//  UserFootage+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_USER_FOOTAGE @"UserFootage"

#import "UserFootage.h"

@interface UserFootage (Logic)

#pragma mark - Find or create
/**
 *  Finds or creates a user footage object with the provided oid.
 *
 *  @param oid     The id of the object.
 *  @param context The managed object context.
 */
+(UserFootage *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context;

@end
