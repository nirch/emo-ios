//
//  Package+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_PACKAGE @"Package"

#import "Package.h"

@interface Package (Logic)

#pragma mark - Find or create
/**
 *  Finds or creates a package object with the provided oid.
 *
 *  @param oid     The id of the object.
 *  @param context The managed object context.
 *
 *  @return Package object.
 */
+(Package *)findOrCreateWithID:(NSString *)oid
                       context:(NSManagedObjectContext *)context;

/**
 *  Fetches all the packages info found in local storage.
 *
 *  @param context The managed object context.
 *
 *  @return An array of packages objects.
 */
+(NSArray *)allPackagesInContext:(NSManagedObjectContext *)context;


/**
 *  The json file name holding the emuticons definitions for this package.
 *
 *  @return NSString with he name of the file.
 */
-(NSString *)jsonFileName;

@end
