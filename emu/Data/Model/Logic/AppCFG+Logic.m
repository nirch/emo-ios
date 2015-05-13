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
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSDictionary *tweaks = appCFG.tweaks;
    if ([tweaks isKindOfClass:[NSDictionary class]]) return tweaks;
    return nil;
}

+(BOOL)tweakedBool:(NSString *)name defaultValue:(BOOL)defaultValue
{
    NSDictionary *tweaks = [self tweakedValues];
    if (tweaks == nil) return defaultValue;

    id value = tweaks[name];
    if ([value isKindOfClass:[NSNumber class]]) return [value boolValue];
    return defaultValue;
}


+(NSTimeInterval)tweakedInterval:(NSString *)name defaultValue:(NSTimeInterval)defaultValue
{
    NSDictionary *tweaks = [self tweakedValues];
    if (tweaks == nil) return defaultValue;
    
    id value = tweaks[name];
    if ([value isKindOfClass:[NSNumber class]]) return [value doubleValue];
    return defaultValue;
}


@end
