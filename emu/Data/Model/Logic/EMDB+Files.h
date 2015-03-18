//
//  EMDB+Files.h
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMDB.h"

#define GROUP_CONTAINER_IDENTIFIER @"group.it.homage.Emu"

@interface EMDB (Files)

+(void)ensureRequiredDirectoriesExist;
+(BOOL)ensureDirPathExists:(NSString *)dirPath;
+(NSString *)createDirectoryNamed:(NSString *)directoryName;
+(NSString *)pathForDirectoryNamed:(NSString *)directoryName;
+(BOOL)pathExists:(NSString *)path;

#pragma mark - Root paths
+(NSURL *)rootURL;
+(NSString *)rootPath;

#pragma mark - Footages
+(NSString *)footagesPath;
+(NSString *)pathForFootageWithOID:(NSString *)footageOID;

#pragma mark - output
+(NSString *)outputPath;
+(NSString *)outputPathForFileName:(NSString *)fileName;

#pragma mark - Resources
+(NSString *)pathForResourceNamed:(NSString *)resourceName;


@end
