//
//  Feature+Logic.m
//  emu
//
//  Created by Aviv Wolf on 18/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Feature+Logic.h"
#import "NSManagedObject+FindAndCreate.h"
#import "EMDB.h"

@implementation Feature (Logic)

+(Feature *)findOrCreateWithOID:(NSString *)oid
                        context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_FEATURE
                                                                   oid:oid
                                                               context:context];
    return (Feature *)object;
}

+(Feature *)findWithOID:(NSString *)oid
                context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_FEATURE
                                                               withID:oid
                                                            inContext:context];
    return (Feature *)object;
}

+(Feature *)findWithPID:(NSString *)pid
                context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid=%@", pid];
    return (Feature *)[NSManagedObject fetchSingleEntityNamed:E_FEATURE
                                                withPredicate:predicate
                                                    inContext:context];
}

#pragma mark - Purchased / unlocked features
+(BOOL)wasFeaturePurchased:(NSString *)oid context:(NSManagedObjectContext *)context
{
    // Find feature object with provided feature oid.
    Feature *feature = [Feature findWithOID:oid context:context];
    
    // Not found? return as not purchased.
    if (feature == nil) return NO;
    
    // Return if purchased or not.
    if (feature.purchased) return feature.purchased.boolValue;
    return NO;
}

-(BOOL)wasUnlocked
{
    // If emu pro was unlocked, consider any feature as unlocked.
    if ([Feature isEmuProUnlockedInContext:self.managedObjectContext]) return YES;
    
    // Emu pro not unlocked. Return if this specific feature was purchased.
    return [Feature wasFeaturePurchased:self.oid context:self.managedObjectContext];
}

+(BOOL)isEmuProUnlockedInContext:(NSManagedObjectContext *)context
{
    return [Feature wasFeaturePurchased:FEATURE_EMU_PRO context:context];
}

+(BOOL)isBlockAdsUnlockedInContext:(NSManagedObjectContext *)context
{
    if ([self isEmuProUnlockedInContext:context]) return YES;
    return [Feature wasFeaturePurchased:FEATURE_BLOCK_ADS  context:context];
}

+(BOOL)isRemoveWatermarksUnlockedInContext:(NSManagedObjectContext *)context
{
    if ([self isEmuProUnlockedInContext:context]) return YES;
    return [Feature wasFeaturePurchased:FEATURE_REMOVE_WATERMARKS  context:context];
}

+(BOOL)isAllowSaveAndCopyUnlockedInContext:(NSManagedObjectContext *)context
{
    if ([self isEmuProUnlockedInContext:context]) return YES;
    return [Feature wasFeaturePurchased:FEATURE_ALLOW_SAVE_AND_COPY context:context];
}

@end
