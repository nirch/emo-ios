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
    
    UserFootage *userFootage = [self findOrCreateWithID:oid
                                                context:context];
    userFootage.framesCount = numberOfFrames;
    userFootage.duration = duration;
    userFootage.timeTaken = date;
    return userFootage;
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
    NSArray *storedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    float storedImagesCount = storedImages.count;
    
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:maxFrames];
    NSInteger previousFrame = 0;
    for (float i = 0;i < maxFrames;i+=1.0) {
        
        // Skip frames as required to produce a list
        // with the required max number of allowed frames.
        // (will not repeat frames).
        NSInteger sourceIndex = ((float)i/(float)maxFrames)*storedImagesCount+1;
        if (sourceIndex == previousFrame) continue;
        
        // Just to be safe, Keep index in bounds.
        sourceIndex = MIN(storedImagesCount,sourceIndex);
        
        // Populate the list with the paths to frames.
        NSString *pathToImage = [SF:ptn, (long)sourceIndex];
        UIImage *image = [UIImage imageWithContentsOfFile:pathToImage];
        if (image != nil) images[(int)i] = image;
        previousFrame = sourceIndex;
    }
    
    // Return the list of frames.
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
