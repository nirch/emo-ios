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
#import "FootageProtocol.h"

@interface Emuticon (Logic)

-(NSComparisonResult)compare:(Emuticon *)otherObject;


// By default will loop emu 5 times when rendering video
#define EMU_DEFAULT_VIDEO_LOOPS_COUNT 5

// By default will just repeat the emu on video render
// 0 - Normal Repeat
// 1 - Boomerang loop
#define EMU_DEFAULT_VIDEO_LOOPS_FX 0

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
 *  Fetches a list of emu objects that are marked as render in HD.
 *
 *  @return NSArray of emus rendered in HD
 */
+(NSArray *)allEmuticonsRenderedInHD;

/**
 *  Fetches all emuticons that were set to preffer a specific footage (ignores emuticons marked as preview)
 *
 *  @param footageOID NSString The footage oid.
 *  @param context    NSManagedObjectContext
 *
 *  @return <#return value description#>
 */
+(NSArray *)allEmuticonsUsingFootageOID:(NSString *)footageOID inContext:(NSManagedObjectContext *)context;

-(NSURL *)thumbURL;
-(NSString *)thumbPath;

/**
 *  The url to the animated gif rendered for this emuticon object.
 *
 *  @return NSURL pointing to the rendered animated gif.
 */
-(NSURL *)animatedGifURL;
-(NSURL *)animatedGifURLInHD:(BOOL)inHD;


/**
 *  The path to the animated gif rendered for this emuticon object;
 *
 *  @return NSString of the path to the rendered animated gif.
 */
-(NSString *)animatedGifPath;
-(NSString *)animatedGifPathInHD:(BOOL)inHD;


/**
 *  The raw data of the animated gif rendered for this emuticon object.
 *
 *  @return NSData of the raw data of the animated gif.
 */
-(NSData *)animatedGifData;
-(NSData *)animatedGifDataInHD:(BOOL)inHD;

/**
 *  The path to the video rendered for this emuticon object;
 *  Always returns a value of where the video *should* be found 
 *  (even if file doesn't currently exist at location)
 *
 *  @return NSString of the path to be used for rendered video.
 */
-(NSString *)videoPath;


/**
 *  The url to the video rendered for this emuticon object.
 *  Return nil if the video isn't found at location (specified by videoPath).
 *
 *  @return NSURL pointing to the rendered video (or nil if file is missing).
 */
-(NSURL *)videoURL;


/**
 *  The raw data of the video rendered for this emuticon object.
 *  (nil if video wasn't rendered)
 *
 *  @return NSData of the raw data of the rendered video (or nil).
 */
-(NSData *)videoData;



/**
 *  Cleans up the emuticon rendered files and deletes the object.
 */
-(void)deleteAndCleanUp;

/**
 *  Just remove the HD output gif file (if exists)
 */
-(void)cleanUpHDOutputGif;

/**
 *  Cleans up the emuticon rendered files and marks it as not rendered
 *  (wasRendered = @NO)
 */
-(void)cleanUp;

/**
 *  Cleanup and/or delete all required resources of the related emuDef.
 *
 *  @param cleanUp         if set to YES, will clean rendered output files (and mark emu as not rendered)
 *  @param removeResources if set to YES, will delete downloaded resources of the related emuDef.
 */
-(void)cleanUp:(BOOL)cleanUp andRemoveResources:(BOOL)removeResources;

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
-(id<FootageProtocol>)mostPrefferedUserFootage;

/**
 *  Returns the related preview footage of an emuticon marked as preview.
 *  If the footage doesn't exist or the emuticon is not marked as a preview
 *  will return nil;
 *
 *  @return UserFootage object of the preview emuticon.
 */
-(UserFootage *)previewUserFootage;

/**
 *  Mark this emu instance as "in focus" and marks all other emus with the same emu def as not in focus.
 */
-(void)gainFocus;


/**
 * URL pointing to the audio file selected for this emuticon 
 * (optional: can be nil).
 */
-(NSURL *)audioFileURL;

-(BOOL)shouldItRenderInHD;
-(void)toggleShouldRenderAsHDIfAvailable;

// Info for uploaded content.
-(NSString *)generateOIDForUpload;
-(NSString *)s3KeyForUploadForOID:(NSString *)oid;
-(NSDictionary *)metaDataForUpload;
-(NSString *)s3KeyForSampledResult;

// Videos
-(BOOL)engagedUserVideoSettings;
-(void)cleanTempVideoResources;
-(void)cleanUpVideoIfNotFullRender;


// Converting info to none core data object
//#define rkRenderType                @"renderType"
//#define rkEmuticonDefOID            @"emuticonDefOID"
//#define rkFootageOID                @"footageOID"
//#define rkBackLayerPath             @"backLayerPath"
//#define rkUserImagesPath            @"userImagesPath"
//#define rkUserMaskPath              @"userMaskPath"
//#define rkUserDynamicMaskPath       @"userDynamicMaskPath"
//#define rkFrontLayerPath            @"frontLayerPath"
//#define rkNumberOfFrames            @"numberOfFrames"
//#define rkDuration                  @"duration"
//#define rkOutputOID                 @"outputOID"
//#define rkPaletteString             @"paletteString"
//#define rkOutputPath                @"outputPath"
//#define rkShouldOutputGif           @"shouldOutputGif"
//#define rkEffects                   @"effects"
//#define rkPositioningScale          @"positioningScale"
//#define rkOutputResolutionWidth     @"outputResolutionWidth"
//#define rkOutputResolutionHeight    @"outputResolutionHeight"
//#define rkRenderInHD                @"renderInHD"

-(CGSize)size;
-(NSString *)resolutionLabel;
-(BOOL)boolWasRenderedInHD:(BOOL)inHD;
-(NSArray *)relatedFootages;
-(BOOL)isJointEmu;

@end
