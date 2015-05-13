//
//  AppCFG+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define E_APP_CFG @"AppCFG"

@class Package;

#import "AppCFG.h"

@interface AppCFG (Logic)

+(AppCFG *)cfgInContext:(NSManagedObjectContext *)context;
-(BOOL)isPackageUsedForOnboarding:(Package *)package;
-(Package *)packageForOnboarding;
-(void)createMissingEmuticonObjectsForMixedScreen;

#pragma mark - Sampled results
-(BOOL)shouldUploadSampledResults;


#pragma mark - tweaked values
+(BOOL)tweakedBool:(NSString *)name defaultValue:(BOOL)defaultValue;
+(NSTimeInterval)tweakedInterval:(NSString *)name defaultValue:(NSTimeInterval)defaultValue;

@end
