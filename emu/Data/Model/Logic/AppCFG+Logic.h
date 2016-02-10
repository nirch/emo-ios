//
//  AppCFG+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define E_APP_CFG @"AppCFG"

@class Package;
@class EmuticonDef;

#import "AppCFG.h"

@interface AppCFG (Logic)

// S3 credentials (upload only)
#define S3_UPLOAD_ACCESS_KEY @"AKIAINLSJGFQCJUIWV3A"
#define S3_UPLOAD_SECRET_KEY @"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"

+(AppCFG *)cfgInContext:(NSManagedObjectContext *)context;
-(BOOL)isPackageUsedForOnboarding:(Package *)package;
-(Package *)packageForOnboarding;
-(EmuticonDef *)emuticonDefForOnboarding;
-(EmuticonDef *)emuticonDefForOnboardingWithPrefferedEmus:(NSArray *)prefferedEmus;

#pragma mark - Sampled results
-(BOOL)shouldUploadSampledResults;

#pragma mark - remote files
-(NSURL *)remoteURLToFile:(NSString *)remoteFile;

#pragma mark - tweaked values
+(NSNumber *)tweakedNumber:(NSString *)name;
//+(BOOL)tweakedBool:(NSString *)name;
+(NSString *)tweakedString:(NSString *)name;
+(BOOL)tweakedBool:(NSString *)name defaultValue:(BOOL)defaultValue;
+(NSInteger)tweakedInteger:(NSString *)name defaultValue:(NSInteger)defaultValue;
+(NSString *)tweakedString:(NSString *)name defaultValue:(NSString *)defaultValue;
+(NSTimeInterval)tweakedInterval:(NSString *)name defaultValue:(NSTimeInterval)defaultValue;

@end
