//
//  AppCFG+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppCFG+Logic.h"
#import "NSManagedObject+FindAndCreate.h"
#import "EMDB.h"
#import "HMPanel.h"

@implementation AppCFG (Logic)

+(AppCFG *)cfgInContext:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_APP_CFG
                                                                   oid:@"default"
                                                               context:context];
    return (AppCFG *)object;
}

-(Package *)packageForOnboarding
{
    // Choose a random package from the available ones.
    NSArray *packages = [Package allPackagesInContext:self.managedObjectContext];
    if (packages.count > 0) {
        NSInteger rndIndex = arc4random() % packages.count;
        return packages[rndIndex];
    }
    return nil;
}

-(EmuticonDef *)emuticonDefForOnboarding
{
    return [self emuticonDefForOnboardingWithPrefferedEmus:nil];
}

-(EmuticonDef *)emuticonDefForOnboardingWithPrefferedEmus:(NSArray *)prefferedEmus
{
    NSArray *emus = self.mixedScreenEmus;
    if (emus == nil) return nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"oid in %@ AND disallowedForOnboardingPreview=%@", emus, @NO];
    NSArray *emuDefs = [NSManagedObject fetchEntityNamed:E_EMU_DEF
                                           withPredicate:predicate
                                               inContext:self.managedObjectContext];

    NSMutableArray *emuDefsWithAvailableLocalResources = [NSMutableArray new];
    for (EmuticonDef *emuDef in emuDefs) {
        if ([emuDef allResourcesAvailable]) {
            [emuDefsWithAvailableLocalResources addObject:emuDef];
        }
    }
    if (emuDefsWithAvailableLocalResources.count<1) {
        REMOTE_LOG(@"CRITICAL ERROR!!! No available emu for onboarding?");
    }
    assert(emuDefsWithAvailableLocalResources.count>0);
    
    // Choose a random emu def from the list.
    NSInteger randomIndex = [self chooseEmuIndexForOnboardingFromList:emuDefsWithAvailableLocalResources
                                                    withPrefferedEmus:prefferedEmus];
    return emuDefsWithAvailableLocalResources[randomIndex];
}


-(NSInteger)chooseEmuIndexForOnboardingFromList:(NSArray *)emus withPrefferedEmus:(NSArray *)prefferedEmus
{
    if (prefferedEmus == nil) return arc4random() % emus.count;

    // Try to get a random one from the preffered list.
    NSMutableArray *prefferedIndexes = [NSMutableArray new];
    for (NSInteger i = 0;i<emus.count;i++) {
        EmuticonDef *emuDef = emus[i];
        if ([prefferedEmus containsObject:emuDef.name]) [prefferedIndexes addObject:@(i)];
    }
    
    // If no preffered available, just use a random one from the complete list.
    if (prefferedIndexes.count<1) return arc4random() % emus.count;

    // Return an index of a random *preffered* emu.
    NSInteger index = [prefferedIndexes[arc4random() % prefferedIndexes.count] integerValue];
    return index;
}



-(void)createMissingEmuticonObjectsForMixedScreen
{
    NSArray *emus = self.mixedScreenEmus;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"oid in %@", emus];
    NSArray *emuDefs = [NSManagedObject fetchEntityNamed:E_EMU_DEF
                                           withPredicate:predicate
                                               inContext:self.managedObjectContext];
    [EmuticonDef createMissingEmuticonsForEmuDefs:emuDefs];
}

-(BOOL)isPackageUsedForOnboarding:(Package *)package
{
    if (package == nil) return NO;
    return [package.oid isEqualToString:self.onboardingUsingPackage];
}


#pragma mark - Sampled results
-(BOOL)shouldUploadSampledResults
{
    NSDictionary *info = self.uploadUserContent;
    if (info == nil || info[@"enabled"] == nil) return NO;
    return [info[@"enabled"] boolValue];
}


#pragma mark - tweaked values
+(NSDictionary *)tweakedValues
{
    if (EMDB.sh.cachedTweakedValues)
        return EMDB.sh.cachedTweakedValues;
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSDictionary *tweaks = appCFG.tweaks;
    if ([tweaks isKindOfClass:[NSDictionary class]]) {
        EMDB.sh.cachedTweakedValues = tweaks;
        return tweaks;
    }
    return nil;
}

+(NSNumber *)tweakedNumber:(NSString *)name
{
    NSDictionary *tweaks = [self tweakedValues];
    if (tweaks == nil) return nil;
    
    id value = tweaks[name];
    if ([value isKindOfClass:[NSNumber class]]) return value;
    return nil;
}

//+(BOOL)tweakedBool:(NSString *)name
//{
//    NSNumber *boolNumber = [self tweakedNumber:name];
//    if (boolNumber) return [boolNumber boolValue];
//    return nil;
//}

+(NSString *)tweakedString:(NSString *)name
{
    NSDictionary *tweaks = [self tweakedValues];
    if (tweaks == nil) return nil;
    
    id value = tweaks[name];
    if ([value isKindOfClass:[NSString class]]) return value;
    return nil;
}

+(BOOL)tweakedBool:(NSString *)name defaultValue:(BOOL)defaultValue
{
    NSNumber *boolNumber = [self tweakedNumber:name];
    if (boolNumber) return [boolNumber boolValue];
    return defaultValue;
}

+(NSInteger)tweakedInteger:(NSString *)name defaultValue:(NSInteger)defaultValue
{
    NSNumber *number = [self tweakedNumber:name];
    if (number) return [number integerValue];
    return defaultValue;
}

+(NSString *)tweakedString:(NSString *)name defaultValue:(NSString *)defaultValue
{
    NSString *str = [self tweakedString:name];
    if (str) return str;
    return defaultValue;
}


+(NSTimeInterval)tweakedInterval:(NSString *)name defaultValue:(NSTimeInterval)defaultValue
{
    NSNumber *number = [self tweakedNumber:name];
    if (number) return [number doubleValue];
    return defaultValue;
}


@end
