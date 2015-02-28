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
 *
 *  @return A UserFootage object.
 */
+(UserFootage *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context;


/**
 *  Finds a user footage object with the provided oid.
 *
 *  @param oid     The id of the object
 *  @param context <#context description#>
 *
 *  @param context The managed object context if exists. nil if doesn't exist.
 */
+(UserFootage *)findWithID:(NSString *)oid
                   context:(NSManagedObjectContext *)context;


/**
 *  The preffered footage used application wide.
 *
 *  @return UserFootage object used application wide as the preffered footage to
 *          render emuticons with.
 */
+(UserFootage *)masterFootage;

/**
 *  Finds or creates a user footage object with the provided info.
 *
 *  @param info    A dictionary containing info about the footage.
 *                 Should include the following info:
 *                      oid - Object id
 *                      
 *
 *
 *
 *  @param context The managed object context.
 *
 *  @return A UserFootage object.
 */
+(UserFootage *)userFootageWithInfo:(NSDictionary *)info
                           context:(NSManagedObjectContext *)context;


/**
 *  The path to the stored images of the footage.
 *
 *  @return A string path to the user images. nil if missing.
 */
-(NSString *)pathForUserImages;



/**
 *  Cleans up the footage related files and deletes the object of the footage.
 */
-(void)deleteAndCleanUp;


@end
