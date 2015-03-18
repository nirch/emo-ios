//
//  Package+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"Package"

#import "Package+Logic.h"
#import "EMDB.h"
#import "EMDB+Files.h"

@implementation Package (Logic)

#pragma mark - Find or create
+(Package *)findOrCreateWithID:(NSString *)oid
                       context:(NSManagedObjectContext *)context;
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_PACKAGE
                                                                   oid:oid
                                                               context:context];
    return (Package *)object;
}

/**
 *  Finds an existing package object with the provided oid.
 *
 *  @param oid     The id of the object.
 *  @param context The managed object context.
 *
 *  @return Package object.
 */
+(Package *)findWithID:(NSString *)oid
               context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_PACKAGE
                                                               withID:oid
                                                            inContext:context];
    return (Package *)object;
}


+(NSArray *)allPackagesInContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    return [self fetchEntityNamed:E_PACKAGE
             withPredicate:predicate
                 inContext:context];
}


-(NSString *)jsonFileName
{
    return [SF:@"%@Package", self.name];
}


-(EmuticonDef *)findEmuDefForPreviewInContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"useForPreview=%@ AND package=%@", @YES, self];
    EmuticonDef *emuDef = (EmuticonDef *)[NSManagedObject fetchSingleEntityNamed:E_EMU_DEF
                                                                   withPredicate:predicate
                                                                       inContext:context];
    return emuDef;
}

-(NSTimeInterval)defaultCaptureDuration
{
    EmuticonDef *emu = [self findEmuDefForPreviewInContext:self.managedObjectContext];
    return emu.duration.doubleValue;
}

//-(NSArray *)allEmuticons
//{
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ALL emuticonDef.package == %@", self];
//    NSArray *result = [NSManagedObject fetchEntityNamed:E_EMU withPredicate:predicate inContext:self.managedObjectContext];
//    return result;
//}

-(NSArray *)emuticonDefsWithNoEmuticons
{
    // Get all emuticons defs in package that have no emuticon yet.
    NSMutableArray *emuDefsWithNoEmuticon = [NSMutableArray new];
    NSArray *emuDefs = [self.emuDefs allObjects];
    
    // Iterate and add to the list
    // any emuticon definition that doesn't have
    // any associated emuticon objects
    // (this will ignore the existance of preview emuticons)
    for (EmuticonDef *emuDef in emuDefs) {
        if ([[emuDef nonPreviewEmuticons] count] < 1) {
            [emuDefsWithNoEmuticon addObject:emuDef];
        }
    }
    
    return emuDefsWithNoEmuticon;
}

-(NSArray *)createMissingEmuticonObjects
{
    NSMutableArray *emus = [NSMutableArray new];
    NSArray *emuDefs = [self emuticonDefsWithNoEmuticons];
    for (EmuticonDef *emuDef in emuDefs) {
        Emuticon *emu = [emuDef spawn];
        [emus addObject:emu];
    }
    HMLOG(TAG, EM_DBG, @"Spawned %@ new emuticons in package %@", @(emus.count), self.name);
    return emus;
}

-(NSArray *)emuticonsWithNoSpecificFootage
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"prefferedFootageOID=nil"];
    NSArray *emus = [NSManagedObject fetchEntityNamed:E_EMU
                                        withPredicate:predicate
                                            inContext:self.managedObjectContext];
    return emus;
}

-(void)cleanUpEmuticonsWithNoSpecificFootage
{
    NSArray *emus = [self emuticonsWithNoSpecificFootage];
    for (Emuticon *emu in emus) {
        [emu cleanUp];
    }
}


-(NSString *)resourcesPath
{
    return [EMDB pathForDirectoryNamed:[SF:@"resources/%@", self.name]];
}


-(BOOL)shouldDownloadZippedPackage
{
    if ([EMDB pathExists:[self resourcesPath]]) return NO;
    if ([self zippedPackageAvailableLocally]) return NO;
    return YES;
}


-(NSString *)zippedPackageResourcesFileName
{
    NSString *theDateString = [EMDB.sh.dateStringForFileFormatter stringFromDate:self.timeUpdated];
    NSString *theTimeString = [EMDB.sh.timeStringForFileFormatter stringFromDate:self.timeUpdated];
    theTimeString = [theTimeString stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSString *fileName = [SF:@"package_%@_%@_%@.zip", self.name, theDateString, theTimeString];
    return fileName;
}

-(NSString *)zippedPackageResourcesFilePath
{
    NSString *path;
    NSString *fileName = [self zippedPackageResourcesFileName];
    
    // If available in bundle, return the path to the file in bundle.
    path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    if (path) return path;
    
    // IF not available in bundle, check if available in temp directory.
    path = [SF:@"%@/%@", [EMDB pathForDirectoryNamed:@"temp"], fileName];
    if ([EMDB pathExists:path])
        return path;
    
    // Zip file unavailable locally.
    return nil;
}

-(BOOL)zippedPackageAvailableLocally
{
    NSString *path = [self zippedPackageResourcesFilePath];
    if (path) {
        return [[NSFileManager defaultManager] fileExistsAtPath:path];
    }
    return NO;
}

-(BOOL)shouldUnzipZippedPackage
{
    return NO;
}


//-(NSURL *)urlForZippedResources
//{
//    AppCFG *cfg = [AppCFG cfgInContext:self.managedObjectContext];
//    
//}

@end
