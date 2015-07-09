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
#import "AppManagement.h"

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @YES];
    return [self fetchEntityNamed:E_PACKAGE withPredicate:predicate inContext:context];
}

+(NSArray *)allPackagesPrioritizedInContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @YES];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES] ];
    
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) return @[];
    return results;
}


+(void)prioritizePackagesWithInfo:(NSDictionary *)priorityInfo context:(NSManagedObjectContext *)context
{
    if (priorityInfo.count < 1) return;
    NSInteger now = (NSInteger)[[NSDate date] timeIntervalSinceReferenceDate];
    
    // Get the packages that need to be prioritized.
    NSArray *oids = priorityInfo.allKeys;
    NSError *error;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND oid in %@", @YES, oids];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;

    NSArray *packages = [context executeFetchRequest:fetchRequest error:&error];
    for (Package *package in packages) {
        NSNumber *priority = priorityInfo[package.oid];
        priority = priority? @(now + priority.integerValue) : @0;
        package.priority = priority;
    }
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
    

    // Not found?
    // Use any emuDef from this package.
    if (emuDef == nil) {
        predicate = [NSPredicate predicateWithFormat:@"package=%@", self];
        emuDef = (EmuticonDef *)[NSManagedObject fetchSingleEntityNamed:E_EMU_DEF
                                                          withPredicate:predicate
                                                              inContext:context];
    }
    
    // Still not found?!
    // Use any emuDef set for preview
    if (emuDef == nil) {
        predicate = [NSPredicate predicateWithFormat:@"useForPreview=%@", @YES];
        emuDef = (EmuticonDef *)[NSManagedObject fetchSingleEntityNamed:E_EMU_DEF
                                                          withPredicate:predicate
                                                              inContext:context];
    }
    
    return emuDef;
}

-(NSTimeInterval)defaultCaptureDuration
{
    EmuticonDef *emu = [self findEmuDefForPreviewInContext:self.managedObjectContext];
    return emu.duration.doubleValue;
}


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
    NSArray *emuDefs = [self emuticonDefsWithNoEmuticons];
    NSArray *emus = [EmuticonDef createMissingEmuticonsForEmuDefs:emuDefs];
    HMLOG(TAG, EM_DBG, @"Spawned %@ new emuticons in package %@", @(emus.count), self.name);
    return emus;
}


-(NSArray *)emuticonsWithNoSpecificFootage
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"prefferedFootageOID=nil AND emuDef.package=%@", self];
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
    // If already unzipped files for the package, don't download it.
    // (missing resources will be downloaded individually as needed)
    if (self.alreadyUnzipped.boolValue)
        return NO;
    
    BOOL pathExists = [EMDB pathExists:[self resourcesPath]];
    BOOL zippedPackageAvailableLocally = [self zippedPackageAvailableLocally];

    #if defined(DEBUG)
    NSString *resourcesPath = [self resourcesPath];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcesPath error:nil];
    HMLOG(TAG,
          EM_VERBOSE,
          @"Checking resources path:%@ exists:%@ availableLocally:%@ filesCount:%@",
          resourcesPath,
          @(pathExists),
          @(zippedPackageAvailableLocally),
          @(dirContents.count));
    #endif
    
    if (pathExists) return NO;
    if (zippedPackageAvailableLocally) return NO;
    return YES;
}


-(NSString *)zippedPackageResourcesFileName
{
    // Use the known file name provided by the server.
    NSString *fileName;
    fileName = self.zipppedPackageFileName;
    if (fileName != nil) return fileName;
    
    // Fallback to the old unreliable way it was done.
    // (Yes, the method of using dates on client side was stupid and unreliable).
    NSString *theDateString = [EMDB.sh.dateStringForFileFormatter stringFromDate:self.timeUpdated];
    NSString *theTimeString = [EMDB.sh.timeStringForFileFormatter stringFromDate:self.timeUpdated];
    theTimeString = [theTimeString stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    fileName = [SF:@"package_%@_%@_%@.zip", self.name, theDateString, theTimeString];
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
    path = [self zippedPackageTempPath];
    if ([EMDB pathExists:path]) return path;
    
    // Zip file unavailable locally.
    return nil;
}


-(NSString *)zippedPackageTempPath
{
    NSString *fileName = [self zippedPackageResourcesFileName];
    return [SF:@"%@/%@", [EMDB pathForDirectoryNamed:@"temp"], fileName];
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
    // If already unzipped files for the package, don't do it again.
    // (missing resources will be downloaded individually as needed)
    if (self.alreadyUnzipped.boolValue)
        return NO;
    
    if ([self zippedPackageAvailableLocally]) return YES;
    return NO;
}

-(NSURL *)urlForZippedResources
{
    AppCFG *cfg = [AppCFG cfgInContext:self.managedObjectContext];
    NSString *urlString = [SF:@"%@/%@/zipped_packages/%@",
                           cfg.baseResourceURL,
                           cfg.bucketName,
                           [self zippedPackageResourcesFileName]];
    
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

-(NSURL *)urlForResourceNamed:(NSString *)resourceName
{
    NSURL *url = [[self urlForResources] URLByAppendingPathComponent:resourceName];
    return url;
}


-(NSURL *)urlForResources
{
    AppCFG *cfg = [AppCFG cfgInContext:self.managedObjectContext];
    NSString *urlString = [SF:@"%@/%@/packages/%@",
                           cfg.baseResourceURL,
                           cfg.bucketName,
                           self.name];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

-(NSURL *)localURLForZippedResources
{
    NSString *path = [self zippedPackageResourcesFilePath];
    if (path == nil) return nil;
    NSURL *url = [NSURL URLWithString:[SF:@"file://%@", path]];
    return url;
}

-(NSURL *)urlForPackageIcon
{
    AppCFG *cfg = [AppCFG cfgInContext:self.managedObjectContext];
    NSString *urlString = [SF:@"%@/%@/packages/%@/%@%@.png",
                           cfg.baseResourceURL,
                           cfg.bucketName,
                           self.name,
                           self.iconName,
                           @"@2x"
                           ];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}



+(Package *)newlyAvailablePackageInContext:(NSManagedObjectContext *)context
{
    // Get latest published package.
    Package *latestPackage = [Package latestPublishedPackageInContext:context];

    // Get the latest presented package.
    AppCFG *appCFG = [AppCFG cfgInContext:context];
    NSDate *previouslyPublishedLatestPackage = [appCFG latestPackagePublishedOn];
    
    if ([latestPackage.firstPublishedOn compare:previouslyPublishedLatestPackage] == NSOrderedDescending) {
        return latestPackage;
    }
    return nil;
}


+(Package *)latestPublishedPackageInContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"firstPublishedOn" ascending:NO] ];
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (!error && results.count>0) {
        return results[0];
    }
    return nil;
}


-(NSString *)tagLabel
{
    return [SF:@"#%@", [self.label lowercaseString]];
}

-(NSString *)localizedLabel
{
    NSString *key = [SF:@"PACKAGE_%@", [self.name uppercaseString]];
    return LSS(key, self.label);
}

-(void)recountRenders
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"emuDef.package=%@ AND wasRendered=%@", self, @YES];
    NSError *error;
    NSInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (error) return;
    self.rendersCount = @(count);
}

+(NSInteger)countNumberOfViewedPackagesInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"viewedByUser=%@", @YES];
    NSError *error;
    NSInteger count = [context countForFetchRequest:fetchRequest error:&error];
    if (error) return 0;
    return count;
}

-(BOOL)doAllEmusHaveSpecificTakes
{
    if ([self emuticonsWithNoSpecificFootage].count == 0) return YES;
    return NO;
}

-(BOOL)hasEmusWithSpecificTakes
{
    if ([self emuticonsWithNoSpecificFootage].count < self.emuDefs.count) return YES;
    return NO;
}


#pragma mark - Sampled results
-(BOOL)resultNeedToBeSampledForEmuOID:(NSString *)emuOID
{
    // Is sampling enabled?
    AppCFG *appCFG = [AppCFG cfgInContext:self.managedObjectContext];
    NSDictionary *info = appCFG.uploadUserContent;
    if (info == nil || info[@"enabled"] == nil || [info[@"enabled"] boolValue] == NO) return NO;
    
    // Does this package need to be sampled?
    info = info[@"upload_user_rendered_results"];
    NSDictionary *sampledPacks = info[@"sampled_packs"];
    if (sampledPacks == nil || sampledPacks[self.oid] == nil || ![sampledPacks[self.oid] boolValue]) return NO;

    // Sampling is enabled. Was an emu chosen in this pack?
    // (if a different emu already chosen, we don't need to sample another one)
    if (self.sampledEmuResultOID != nil && ![emuOID isEqualToString:self.sampledEmuResultOID]) return NO;

    // Make sure number of samples didn't reach max allowed.
    NSInteger maxUploads = info[@"max_uploads_per_user_per_pack"]?[info[@"max_uploads_per_user_per_pack"] integerValue]:3;
    if (self.sampledEmuCount.integerValue >= maxUploads) return NO;
    
    // All is well, another sample should be uploaded for this emu;
    self.sampledEmuResultOID = emuOID;
    return YES;
}

-(NSComparisonResult)compare:(Package *)otherObject
{
    return [self.oid compare:otherObject.oid];
}

@end
