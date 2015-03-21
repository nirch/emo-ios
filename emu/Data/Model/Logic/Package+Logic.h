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
 *  Finds an existing package object with the provided oid.
 *
 *  @param oid     The id of the object.
 *  @param context The managed object context.
 *
 *  @return Package object.
 */
+(Package *)findWithID:(NSString *)oid
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

/**
 *  Find an emuticon definition in this package
 *  that is marked to be used in previews.
 *
 *  @param context The managed object context.
 *
 *  @return EmuticonDef object or nil if none found.
 */
-(EmuticonDef *)findEmuDefForPreviewInContext:(NSManagedObjectContext *)context;

/**
 *  The default capture duration when capturing footage for this package.
 *
 *  @return NSTimeInterval of the duration.
 */
-(NSTimeInterval)defaultCaptureDuration;


/**
 *  Create one emuticon object for each emuticon definition in this package.
 *  if emuticon object already exists for an emuticon definition, will skip it.
 *
 *  @return An array of the newly created objects.
 */
-(NSArray *)createMissingEmuticonObjects;


/**
 *
 */
-(void)cleanUpEmuticonsWithNoSpecificFootage;


/**
 *  The directory the resources of the package are stored in.
 *
 *  @return
 */
-(NSString *)resourcesPath;


/**
 *  Is the zipped resources should be downloaded for this package?
 *
 *  @return YES if a zipped package should be downloaded.
 */
-(BOOL)shouldDownloadZippedPackage;


/**
 *  Is the zipped resources available locally and should be unzipped?
 *
 *  @return YES if a zipped package is available locally and should be unzipped.
 */
-(BOOL)shouldUnzipZippedPackage;


/**
 *  The remote (s3 or server) url of the zip file containing all resources for the package.
 *
 *  @return NSURL pointing to the zip file on the web.
 */
-(NSURL *)urlForZippedResources;


/**
 *  The local (bundled or resources dir) url of the zip file containing all resources for the package.
 *
 *  @return NSURL pointing to the local zip file. if file doesn't exist, will return nil.
 */
-(NSURL *)localURLForZippedResources;

/**
 *  The local url for the temp zip file. Will return the url even if the file doesn't exist at that location.
 *
 *  @return The NSURL pointing to the position of where a zip may be found.
 */
-(NSString *)zippedPackageTempPath;

@end
