//
//  UserFootage+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_USER_FOOTAGE @"UserFootage"

#import "UserFootage.h"

typedef NS_ENUM(NSInteger, EMFootageTypeSupport) {
    EMFootageTypeSupportUndefined       = 0,
    EMFootageTypeSupportOldPNGSequence  = 1,
    EMFootageTypeSupportHSDKVideo       = 2
};



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
 *  Creates a user footage object with the provided oid and info provided by the HSDK capture session.
 *
 *  @param oid     The id of the object
 *  @param captureInfo    Information about the recording provided by the HSDK capture session.
 *  @param context The managed object context.
 *
 *  @return new UserFootage object.
 */
+(UserFootage *)newFootageWithID:(NSString *)oid
                     captureInfo:(NSDictionary *)captureInfo
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
 *  Check if more than a single footage exist.
 *
 *  @param context The managed object context.
 *
 *  @return YES if footages count > 1. NO otherwise.
 */
+(BOOL)multipleAvailableInContext:(NSManagedObjectContext *)context;


/**
 *  Returns an array of all user footage objects.
 *
 *  @return NSArray of UserFootage objects.
 */
+(NSArray *)allUserFootages;

/**
 *  The path to the stored images of the footage.
 *
 *  @return A string path to the user images. nil if missing.
 */
-(NSString *)pathForUserImages; // Deprecated (files should be deleted)

// New style footage files
-(NSString *)pathToUserGif;
-(NSString *)pathToUserVideo;
-(NSString *)pathToUserDMaskVideo;
-(NSString *)pathToUserThumb;
-(NSString *)pathToUserAudio;

/**
 *  NSURL to the first image of the footage.
 *
 *  @return NSURL of the first image in the footage or nil if missing.
 */
-(NSURL *)urlToThumbImage;

/**
 *  UIImage of the thumb image for this footage.
 *
 *  @return UIImage of the thumb image of this footage.
 */
-(UIImage *)thumbImage;

/**
 *  The path pattern for creating the paths to all images of the footage by index.
 *
 *  @return NSString that can be used in "NSString stringWithFormat"
 *          The part of the string that can be used in format is: "img-%ld.png"
 */
-(NSString *)imagesPathPTN;


/**
 *  NSURL to the Nth image of the footage.
 *
 *  @param imageIndex The index of the image of the footage.
 *
 *  @return NSURL of the Nth image of the footage
 */
-(NSURL *)urlToImageWithIndex:(NSInteger)imageIndex;

/**
 *  Cleans up the footage related files and deletes the object of the footage.
 */
-(void)deleteAndCleanUp;

/**
 *  Delete the old style png sequence footage files.
 */
-(void)deleteOldStylePngSequenceFiles;

/**
 *  Is captured in 480p or above?
 *
 *  @return BOOL value indicating if footage taken in 480x480 or above or not.
 */
-(BOOL)isHD;

/**
 *  Predicate for filtering in only footages in HD.
 *
 *  @return NSPredicate for hd (>240p) footages.
 */
+(NSPredicate *)predicateForHD;

/**
 *  Indicates if any footage taken in higher definition.
 *
 *  @param context NSManagedObjectContext the context.
 *
 *  @return YES if at least one footage was take in > 240p.
 */
+(BOOL)anyHDFootageExistsInContext:(NSManagedObjectContext *)context;


-(NSArray *)imagesSequenceWithMaxNumberOfFrames:(NSInteger)maxFrames;

+(NSArray *)imagesSequenceWithMaxNumberOfFrames:(NSInteger)maxFrames
                                            ptn:(NSString *)ptn
                                           path:(NSString *)path;

-(NSArray *)imagesSequencePaths;

-(BOOL)isPNGSequenceAvailable;
-(BOOL)isGIFAvailable;
-(BOOL)isCapturedVideoAvailable;
-(BOOL)isAudioAvailable;

/**
 *  Checks that the resources of this footage are available.
 *
 *  @return YES if required resources for this footage are available.
 */
-(BOOL)validateResources;

@end
