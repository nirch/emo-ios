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

@implementation Emuticon (Logic)

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
    NSData *gifData = [[NSData alloc] initWithContentsOfFile:path];
    return gifData;
}


-(NSURL *)videoURL
{
    NSString *outputPath = [self videoPath];
    NSURL *url = [NSURL URLWithString:[SF:@"file://%@" , outputPath]];
    return url;
}


-(NSString *)videoPath
{
    NSString *videoName = [SF:@"%@.mp4", self.oid];
    NSString *outputPath = [EMDB outputPathForFileName:videoName];
    return outputPath;
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

    // Mark it as not rendered.
    self.wasRendered = @NO;
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

@end
