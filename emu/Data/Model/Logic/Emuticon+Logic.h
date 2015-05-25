//
//  EmuticonDef+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define E_EMU @"Emuticon"

@class UserFootage;
@class Package;

#import "Emuticon.h"

@interface Emuticon (Logic)

/**
 *  Finds emuticon object with the provided oid.
 *
 *  @param oid     The id of the object
 *  @param context The managed object context.
 */
+(Emuticon *)findWithID:(NSString *)oid
                context:(NSManagedObjectContext *)context;

/**
 *  Finds emuticon object with the provided name in a package.
 *
 *  @param name    The name of the emuticon
 *  @param package The package of the emuticon
 *  @param context The managed object context.
 *
 *  @return The emuticon object if found. nil otherwise.
 */
+(Emuticon *)findWithName:(NSString *)name
                  package:(Package *)package
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
 *  Create a new emuticon object related to the given emuticon definition.
 *
 *  @param emuticonDef An emuticon definition
 *  @param context     The managed object context.
 *
 *  @return An emuticon object.
 */
+(Emuticon *)newForEmuticonDef:(EmuticonDef *)emuticonDef
                       context:(NSManagedObjectContext *)context;

/**
 *  Fetches all emuticons in a given package (ignores emuticons marked as preview)
 *
 *  @param package The related Package object.
 *
 *  @return An array of emuticons related to the given package.
 */
+(NSArray *)allEmuticonsInPackage:(Package *)package;


/**
 *  The url to the animated gif rendered for this emuticon object.
 *
 *  @return NSURL pointing to the rendered animated gif.
 */
-(NSURL *)animatedGifURL;


/**
 *  The path to the animated gif rendered for this emuticon object;
 *
 *  @return NSString of the path to the rendered animated gif.
 */
-(NSString *)animatedGifPath;


/**
 *  The raw data of the animated gif rendered for this emuticon object.
 *
 *  @return NSData of the raw data of the animated gif.
 */
-(NSData *)animatedGifData;


/**
 *  The url to the video rendered for this emuticon object.
 *
 *  @return NSURL pointing to the rendered video.
 */
-(NSURL *)videoURL;


/**
 *  The path to the video rendered for this emuticon object;
 *
 *  @return NSString of the path to the rendered animated gif.
 */
-(NSString *)videoPath;


/**
 *  Cleans up the emuticon rendered files and deletes the object.
 */
-(void)deleteAndCleanUp;


/**
 *  Cleans up the emuticon rendered files and marks it as not rendered
 *  (wasRendered = @NO)
 */
-(void)cleanUp;


/**
 *  The preffered user footage oid for this emuticon.
 *  
 *  Will use the most preffered footage according to priority.
 *  The priority is higher the more specific the preference is.
 *  (will use emuticon specific preference first, package second and app wide last).
 *
 *  @return NSString oid of the most preffered user footage.
 */
-(NSString *)mostPrefferedUserFootageOID;


/**
 *  The preffered user footage for this emuticon.
 *
 *  Will use the most preffered footage according to priority.
 *  The priority is higher the more specific the preference is.
 *  (will use emuticon specific preference first, package second and app wide last).
 *
 *  @return UserFootage of the most preffered user footage.
 */
-(UserFootage *)mostPrefferedUserFootage;

/**
 *  Returns the related preview footage of an emuticon marked as preview.
 *  If the footage doesn't exist or the emuticon is not marked as a preview
 *  will return nil;
 *
 *  @return UserFootage object of the preview emuticon.
 */
-(UserFootage *)previewUserFootage;


/**
 * URL pointing to the audio file selected for this emuticon 
 * (optional: can be nil).
 */
-(NSURL *)audioFileURL;



-(NSString *)s3KeyForSampledResult;


-(NSDictionary *)s3MetaDataForSampledResult;

@end
