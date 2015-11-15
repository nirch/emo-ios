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

-(NSURL *)urlToThumbImage
{
    return [self urlToImageWithIndex:1];
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

-(void)cleanUp
{
    // Delete all footage files.
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[self pathForUserImages] error:nil];
}

@end
