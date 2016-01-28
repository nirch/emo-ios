//
//  UserFootage+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "UserFootage+Logic.h"
#import "EMDB.h"
#import "EMDB+Files.h"

@implementation UserFootage (Logic)

#pragma mark - Find or create
+(UserFootage *)findOrCreateWithID:(NSString *)oid
                      context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_USER_FOOTAGE
                                                                   oid:oid
                                                               context:context];
    return (UserFootage *)object;
}

+(UserFootage *)findWithID:(NSString *)oid
                   context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_USER_FOOTAGE
                                                               withID:oid
                                                            inContext:context];
    return (UserFootage *)object;
}

+(UserFootage *)masterFootage
{
    // Get the oid of the master footage from app configuration.
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSString *masterFootageOID = appCFG.prefferedFootageOID;
    if (masterFootageOID == nil) return nil;
    
    // Find and return the master footage object.
    return [self findWithID:masterFootageOID
                    context:EMDB.sh.context];
}


+(UserFootage *)userFootageWithInfo:(NSDictionary *)info
                            context:(NSManagedObjectContext *)context
{
    NSString *oid               = info[emkOID];
    NSNumber *numberOfFrames    = info[emkNumberOfFrames];
    NSNumber *duration          = info[emkDuration];
    NSDate *date                = info[emkDate];
    
    // Find existing footage
    UserFootage *userFootage = [self findWithID:oid context:context];
    if (userFootage == nil) {
        // Doesn't exist yet, create new one.
         userFootage = [self findOrCreateWithID:oid context:context];

        // In older version, the default was 240x240
        // In newer versions, the default is 480x480
        userFootage.footageWidth = @(480);
        userFootage.footageHeight = @(480);
    }
    userFootage.framesCount = numberOfFrames;
    userFootage.duration = duration;
    userFootage.timeTaken = date;
    return userFootage;
}

+(NSArray *)allUserFootages
{
    NSArray *all = [NSManagedObject fetchEntityNamed:E_USER_FOOTAGE
                                        withPredicate:nil
                                            inContext:EMDB.sh.context];
    return all;
}

-(BOOL)isHD
{
    if (self.footageWidth == nil) return NO;
    if (self.footageWidth.integerValue <= 240) return NO;
    return YES;
}

+(NSPredicate *)predicateForHD
{
    return [NSPredicate predicateWithFormat:@"footageWidth>%@",@(EMU_DEFAULT_WIDTH)];
}

+(BOOL)anyHDFootageExistsInContext:(NSManagedObjectContext *)context
{
    NSInteger count = [EMDB countEntityNamed:E_USER_FOOTAGE
                                   predicate:[UserFootage predicateForHD]
                                   inContext:context];
    return count > 0;
}

+(BOOL)multipleAvailableInContext:(NSManagedObjectContext *)context
{
    NSInteger count = [EMDB countEntityNamed:E_USER_FOOTAGE
                                   predicate:nil
                                   inContext:context];
    return count > 1;
}

-(NSString *)pathForUserImages
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@", self.oid]];
    return path;
}

-(NSString *)pathToUserGif
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@_footage.gif", self.oid]];
    return path;
}

-(NSString *)pathToUserThumb
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@_footage.png", self.oid]];
    return path;
}

-(NSString *)pathToUserVideo
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@_footage.mov", self.oid]];
    return path;
}

-(NSString *)pathToUserDMaskVideo
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@_footage_dmask.mov", self.oid]];
    return path;
}

-(NSString *)pathToUserAudio
{
    NSString *footagesPath = [EMDB footagesPath];
    NSString *path = [footagesPath stringByAppendingPathComponent:[SF:@"/%@_footage.wav", self.oid]];
    return path;
}

-(NSURL *)urlToThumbImage
{
    return [NSURL fileURLWithPath:[self pathToUserThumb]];
}


-(UIImage *)thumbImage
{
    UIImage *image = [UIImage imageWithContentsOfFile:[[self urlToThumbImage] path]];
    return image;
}

-(NSString *)imagesPathPTN
{
    NSMutableString *s = [NSMutableString new];
    [s appendString:[self pathForUserImages]];
    [s appendString:@"/img-%ld.png"];
    return s;
}

-(NSArray *)imagesSequencePaths
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [self pathForUserImages];
    NSArray *storedImagesPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *imagesPaths = [NSMutableArray new];
    for (NSInteger i=1;i<=storedImagesPaths.count;i++) {
        NSString *path = [SF:[self imagesPathPTN],i];
        if ([fm fileExistsAtPath:path]) {
            [imagesPaths addObject:path];
        }
    }
    return imagesPaths;
}


-(NSArray *)imagesSequenceWithMaxNumberOfFrames:(NSInteger)maxFrames
{
    NSString *ptn = [self imagesPathPTN];
    NSString *path = [self pathForUserImages];
    return [UserFootage imagesSequenceWithMaxNumberOfFrames:maxFrames
                                                        ptn:ptn
                                                       path:path];
}

+(NSArray *)imagesSequenceWithMaxNumberOfFrames:(NSInteger)maxFrames
                                            ptn:(NSString *)ptn
                                           path:(NSString *)path
{
    NSError *error;
    
    // Count the number of stored images.
    NSMutableArray *images = [NSMutableArray new];
    NSArray *storedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    float storedImagesCount = storedImages.count;
    
    if (storedImages.count <= maxFrames) {
        // Just load all stored images and return them.
        images = [NSMutableArray new];
        for (int i=0;i<storedImages.count;i++) {
            NSString *pathToImage = [SF:ptn, i];
            UIImage *image = [UIImage imageWithContentsOfFile:pathToImage];
            if (image != nil) [images addObject:image];
        }
    } else {
        // Skip frames if we got too many. Allow only up to the max number of frames.
        images = [NSMutableArray new];
        float i = 0;
        NSInteger previousFrame = 0;
        while (i<maxFrames) {
            i+=1.0f;
            NSInteger sourceIndex = ((float)i/(float)maxFrames)*storedImagesCount+1;
            if (sourceIndex == previousFrame) continue;
            sourceIndex = MIN(storedImagesCount,sourceIndex);
            NSString *pathToImage = [SF:ptn, (long)sourceIndex];
            UIImage *image = [UIImage imageWithContentsOfFile:pathToImage];
            if (image != nil) [images addObject:image];
            previousFrame = sourceIndex;
        }
    }
    return images;
}


-(NSURL *)urlToImageWithIndex:(NSInteger)imageIndex
{
    NSString *pathToImage = [SF:[self imagesPathPTN], (long)imageIndex];
    NSURL *url = [NSURL fileURLWithPath:pathToImage];
    return url;
}

-(void)deleteAndCleanUp
{
    // Delete all footage files.
    [self cleanUp];
    
    // Delete the object.
    [self.managedObjectContext deleteObject:self];
}

-(void)deleteOldStylePngSequenceFiles
{
    // Delete old style footages files.
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[self pathForUserImages] error:nil];
}

-(void)cleanUp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[self pathForUserImages] error:nil];
    [fm removeItemAtPath:[self pathToUserGif] error:nil];
    [fm removeItemAtPath:[self pathToUserVideo] error:nil];
    [fm removeItemAtPath:[self pathToUserDMaskVideo] error:nil];
}

-(BOOL)isPNGSequenceAvailable
{
    if (self.pngSequenceAvailable == nil) return NO;
    return self.pngSequenceAvailable.boolValue;
}

-(BOOL)isGIFAvailable
{
    if (self.gifAvailable == nil) return NO;
    return self.gifAvailable.boolValue;
}

-(BOOL)isCapturedVideoAvailable
{
    if (self.capturedVideoAvailable == nil) return NO;
    return self.capturedVideoAvailable.boolValue;
}

-(BOOL)isAudioAvailable
{
    if (self.audioAvailable == nil) return NO;
    return self.audioAvailable.boolValue;
}

+(UserFootage *)newFootageWithID:(NSString *)oid
                     captureInfo:(NSDictionary *)captureInfo
                         context:(NSManagedObjectContext *)context
{
    if (![captureInfo[@"writer_type"] isEqualToString:@"HFWriterVideo"]) {
        // Must use the new style HSDK footage created by HSDK capture session.
        return nil;
    }
    
    // New style footage. Captured video files using HSDK capture session.
    UserFootage *footage = [UserFootage findOrCreateWithID:oid context:context];
    footage.gifAvailable = @NO;
    footage.pngSequenceAvailable = @NO;
    footage.duration = captureInfo[@"duration"];
    footage.footageWidth = @480;
    footage.footageHeight = @480;
    footage.timeTaken = [NSDate date];
    footage.capturedVideoAvailable = @YES;
    
    NSDictionary *outputFiles = captureInfo[@"output_files"];
    NSString *outputPath = captureInfo[@"output_path"];
    NSString *videoPath = [outputPath stringByAppendingPathComponent:outputFiles[@"captured"]];
    NSString *videoDMaskPath = [outputPath stringByAppendingPathComponent:outputFiles[@"mask"]];
    NSString *audioPath = [outputPath stringByAppendingPathComponent:outputFiles[@"audio"]];
    
    // Move the captured video files to their final path.
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm moveItemAtPath:videoPath toPath:[footage pathToUserVideo] error:nil];
    [fm moveItemAtPath:videoDMaskPath toPath:[footage pathToUserDMaskVideo] error:nil];
    if (audioPath) {
        [fm moveItemAtPath:audioPath toPath:[footage pathToUserAudio] error:nil];
        footage.audioAvailable = @YES;
    }
    
    // Return the new footage object.
    return footage;
}

-(BOOL)validateResources
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([self isCapturedVideoAvailable]) {
        if ([fm fileExistsAtPath:[self pathToUserVideo]] == NO) return NO;
        if ([fm fileExistsAtPath:[self pathToUserDMaskVideo]] == NO) return NO;
    }
    return YES;
}


@end
