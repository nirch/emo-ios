//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "Emuticon+Logic.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "HMParams.h"
#import "HMPanel.h"
#import "AppManagement.h"
#import "EMCaches.h"

@implementation Emuticon (Logic)

-(NSComparisonResult)compare:(Emuticon *)otherObject
{
    return [self.oid compare:otherObject.oid];
}

+(Emuticon *)findWithID:(NSString *)oid
                context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_EMU
                                                               withID:oid
                                                            inContext:context];
    return (Emuticon *)object;
}

+(Emuticon *)findWithName:(NSString *)name
                  package:(Package *)package
                  context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"emuDef.name=%@ AND emuDef.package=%@", name, package];
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_EMU
                                                        withPredicate:predicate
                                                            inContext:context];
    return (Emuticon *)object;
}


+(Emuticon *)previewWithOID:(NSString *)oid
                 footageOID:(NSString *)footageOID
             emuticonDefOID:(NSString *)emuticonDefOID
                    context:(NSManagedObjectContext *)context;
{
    // footage and emuticon definition must exist.
    UserFootage *userFootage = [UserFootage findWithID:footageOID context:context];
    EmuticonDef *emuDef = [EmuticonDef findWithID:emuticonDefOID context:context];
    if (userFootage == nil || emuDef == nil) return nil;
    
    // Create the emuticon preview object.
    Emuticon *emu = (Emuticon *)[NSManagedObject findOrCreateEntityNamed:E_EMU
                                                                     oid:oid
                                                                 context:context];
    emu.prefferedFootageOID = userFootage.oid;
    emu.emuDef = emuDef;
    emu.usageCount = @0;
    emu.isPreview = @YES;
    return emu;
}


+(Emuticon *)newForEmuticonDef:(EmuticonDef *)emuticonDef
                       context:(NSManagedObjectContext *)context
{
    NSString *oid = [[NSUUID UUID] UUIDString];
    Emuticon *emu = (Emuticon *)[NSManagedObject findOrCreateEntityNamed:E_EMU
                                                                     oid:oid
                                                                 context:context];
    emu.emuDef = emuticonDef;
    return emu;
}


+(NSArray *)allEmuticonsInPackage:(Package *)package
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.package=%@", @NO, package];
    NSArray *emus = [NSManagedObject fetchEntityNamed:E_EMU
                                        withPredicate:predicate
                                            inContext:EMDB.sh.context];
    return emus;
}


-(NSURL *)animatedGifURL
{
    NSString *outputPath = [self animatedGifPath];
    NSURL *url = [NSURL URLWithString:[SF:@"file://%@" , outputPath]];
    return url;
}


-(NSString *)animatedGifPath
{
    NSString *gifName = [SF:@"%@.gif", self.oid];
    NSString *outputPath = [EMDB outputPathForFileName:gifName];
    return outputPath;
}


-(NSData *)animatedGifData
{
    NSString *path = [self animatedGifPath];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    return data;
}


-(NSString *)videoPath
{
    // Video files are always stored in temp directory (and deleted when not required)
    NSString *path = [SF:@"%@%@.mp4", NSTemporaryDirectory(), self.oid];
    return path;
}


-(NSURL *)videoURL
{
    NSString *path = [self videoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:[SF:@"file://%@" , path]];
    if ([fm fileExistsAtPath:path]) {
        return url;
    }
    return nil;
}


-(NSData *)videoData
{
    NSString *path = [self videoPath];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    return data;
}


-(void)deleteAndCleanUp
{
    // Delete rendered files
    [self cleanUp];
    
    // Delete the object
    [self.managedObjectContext deleteObject:self];
}


-(void)cleanUp
{
    // Delete rendered output files
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    [fm removeItemAtPath:[self animatedGifPath] error:&error];
    [fm removeItemAtPath:[self videoPath] error:&error];
    [EMCaches.sh removeCachedGifForEmu:self];

    // Mark it as not rendered.
    self.wasRendered = @NO;
    self.renderedSampleUploaded = @NO;
}



-(NSString *)mostPrefferedUserFootageOID
{
    // Will look up for the preffered user footage
    // with the most specific with the highest priority.
    
    // Specific to this emuticon
    NSString *oid = self.prefferedFootageOID;
    
    if (oid == nil) {
        // Specific to the related package
        oid = self.emuDef.package.prefferedFootageOID;
    }
    
    if (oid == nil) {
        // Preffered application wide
        AppCFG *appCFG = [AppCFG cfgInContext:self.managedObjectContext];
        oid = appCFG.prefferedFootageOID;
    }
    
    return oid;
}


-(UserFootage *)mostPrefferedUserFootage
{
    NSString *footageOID = [self mostPrefferedUserFootageOID];
    UserFootage *userFootage = [UserFootage findWithID:footageOID
                                               context:self.managedObjectContext];
    return userFootage;
}


-(UserFootage *)previewUserFootage
{
    if (!self.isPreview.boolValue) return nil;
    if (self.prefferedFootageOID == nil) return nil;
    return [UserFootage findWithID:self.prefferedFootageOID
                           context:self.managedObjectContext];
}



-(NSURL *)audioFileURL
{
    if (self.audioFilePath == nil) return nil;
    
    // Check if file exists.
//    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.audioFilePath];
//    if (!fileExists) return nil;
    
    // File exists, return url.
    return [NSURL URLWithString:self.audioFilePath];
}


-(NSString *)s3KeyForSampledResult
{
    NSString *deviceIdentifier = UIDevice.currentDevice.identifierForVendor.UUIDString;
    NSString *key = [SF:@"users_content/sampled_results/%@_%@_%@_%@.gif", deviceIdentifier, self.emuDef.package.name, self.emuDef.name, self.rendersCount];
    key = [key stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    return key;
}


-(NSString *)generateOIDForUpload
{
    NSString *oid = [EMDB generateOID];
    return oid;
}

-(NSString *)s3KeyForUploadForOID:(NSString *)oid
{
    NSString *key = [SF:@"users_content/shared/%@.gif", oid];
    return key;
}

-(NSDictionary *)metaDataForUpload
{
    HMParams *params = [HMParams new];
    [params addKey:@"emuticonDefOID" value:self.emuDef.oid];
    [params addKey:@"emuticonDefName" value:self.emuDef.name];
    [params addKey:@"packageOID" value:self.emuDef.package.oid];
    [params addKey:@"packageName" value:self.emuDef.package.name];
    [params addKey:@"renderCount" value:[self.rendersCount description]];
    [params addKey:@"deviceModel" value:[AppManagement deviceModelName]];
    [params addKey:@"deviceIdentifier" value:UIDevice.currentDevice.identifierForVendor.UUIDString];
    [params addKey:@"deviceName" value:[[UIDevice currentDevice] name]];    
    return params.dictionary;
}


-(BOOL)engagedUserVideoSettings
{
    if (self.videoLoopsEffect) return YES;
    if (self.videoLoopsCount) return YES;
    if (self.audioFileURL) return YES;
    return NO;
}


-(void)cleanTempVideoResources
{
    NSString *tempOutputPath = NSTemporaryDirectory();
    NSString *outputVideoPath1 = [SF:@"%@/%@.mp4", tempOutputPath, self.oid];
    NSString *outputVideoPath2 = [SF:@"%@/%@-ws.mp4", tempOutputPath, self.oid];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:outputVideoPath1 error:nil];
    [fm removeItemAtPath:outputVideoPath2 error:nil];
}


@end
