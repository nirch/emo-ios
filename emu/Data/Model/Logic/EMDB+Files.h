//
//  EMDB+Files.h
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMDB.h"

@interface EMDB (Files)

+(void)ensureRequiredDirectoriesExist;
+(BOOL)ensureDirPathExists:(NSString *)dirPath;

#pragma mark - Footages
+(NSString *)footagesPath;
+(NSString *)pathForFootageWithOID:(NSString *)footageOID;

#pragma mark - output
+(NSString *)outputPath;
+(NSString *)outputPathForFileName:(NSString *)fileName;

#pragma mark - Resources
+(NSString *)pathForResourceNamed:(NSString *)resourceName;


@end
