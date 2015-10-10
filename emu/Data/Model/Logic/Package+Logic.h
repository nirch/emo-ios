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
 *  Fetches all the active packages info found in local storage.
 *
 *  @param context The managed object context.
 *
 *  @return An array of packages objects.
 */
+(NSArray *)allPackagesInContext:(NSManagedObjectContext *)context;


/**
 *  Fetches all the active packages info found in local storage, ordered by priority.
 *
 *  @param context The managed object context.
 *
 *  @return An array of packages objects.
 */
+(NSArray *)allPackagesPrioritizedInContext:(NSManagedObjectContext *)context;


/**
 *  Reorders packages in local storage, given new priority info.
 *
 *  @param priorityInfo     - The info about the packages to prioritize.
 *  @param context          - The managed object context.
 *
 */
+(void)prioritizePackagesWithInfo:(NSDictionary *)priorityInfo context:(NSManagedObjectContext *)context;


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
 *  A remote url for resource with the given name.
 *
 *  @param resourceName The file name of the resource.
 *
 *  @return NSURL pointing to where the resource is on the web.
 */
-(NSURL *)urlForResourceNamed:(NSString *)resourceName;


/**
 *  A remote url for folder of resources of this package.
 *
 *  @return NSURL pointing to where the resources of the pack are stored.
 */
-(NSURL *)urlForResources;

/**
 *  A list of emuticons with no set specific footage.
 *
 *  @return NSArray of such emu objects.
 */
-(NSArray *)emuticonsWithNoSpecificFootage;


/**
 *  A list of all emuticons OIDs in this pack.
 *  (preview temp emus are ignored)
 *
 *  @return NSArray of all OIDs of emuticons in the pack.
 */
-(NSArray *)emuticonsOIDS;

+(Package *)newlyAvailablePackageInContext:(NSManagedObjectContext *)context;
+(Package *)latestPublishedPackageInContext:(NSManagedObjectContext *)context;
-(NSString *)tagLabel;
-(void)recountRenders;
+(NSInteger)countNumberOfViewedPackagesInContext:(NSManagedObjectContext *)context;
-(BOOL)doAllEmusHaveSpecificTakes;
-(BOOL)hasEmusWithSpecificTakes;
-(NSString *)localizedLabel;

/**
 *  Always update the priority field using this method.
 *  it takes care of also 
 */
-(void)updatePriority:(NSNumber *)priority;

/**
 *
 *
 *  @param shareMethodName
 *
 *  @return
 */
-(NSString *)sharingHashTagsStringForShareMethodNamed:(NSString *)shareMethodName;

#pragma mark - Package resources
/**
 *  The url of the (old and soon to be deprecated) package icon.
 *
 *  @return NSURL to the package icon.
 */
-(NSURL *)urlForPackageIcon;

/**
 *  The url of the package banner resource.
 *
 *  @return NSURL to the package banner resource.
 */
-(NSURL *)urlForPackageBanner;

/**
 *  The url of the package wide banner resource.
 *
 *  @return NSURL to the package wide banner resource.
 */
-(NSURL *)urlForPackageBannerWide;

/**
 *  The url of the big poster
 *
 *  @return NSURL to the package poster (may be png or animated gif). May be nil.
 */
-(NSURL *)urlForPackagePoster;

/**
 *  The url of the big poster overlay
 *
 *  @return NSURL to the package poster overlay (should be png with alpha). May be nil.
 */
-(NSURL *)urlForPackagePosterOverlay;




#pragma mark - Sampled results
-(BOOL)resultNeedToBeSampledForEmuOID:(NSString *)emuOID;

-(NSComparisonResult)compare:(Package *)otherObject;

@end
