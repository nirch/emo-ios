//
//  EMDB+Files.m
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMDB+Files.h"

@implementation EMDB (Files)


+(void)ensureRequiredDirectoriesExist
{
    [self createDirectoryNamed:@"footages"];
    [self createDirectoryNamed:@"output"];
}


#pragma mark - general paths and files creation
+(NSString *)rootPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
}


+(NSString *)createDirectoryNamed:(NSString *)directoryName
{
    // Get the paths
    NSString *rootPath = [EMDB rootPath];
    NSString *dirPath = [rootPath stringByAppendingPathComponent:[SF:@"/%@", directoryName]];
    
    // Create the directory if missing.
    [self ensureDirPathExists:dirPath];
    
    return dirPath;
}

+(BOOL)ensureDirPathExists:(NSString *)dirPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dirPath])
        [fm createDirectoryAtPath:dirPath
      withIntermediateDirectories:NO
                       attributes:nil
                            error:nil];
    return [fm fileExistsAtPath:dirPath];
}

#pragma mark - Footages
+(NSString *)footagesPath
{
    NSString *fp = [SF:@"%@/%@", [self rootPath], @"footages"];
    return fp;
}

+(NSString *)pathForFootageWithOID:(NSString *)footageOID
{
    // Get the path name
    NSString *path = [SF:@"%@/%@", [self footagesPath], footageOID];    
    return path;
}


+(NSString *)outputPath
{
    NSString *op = [SF:@"%@/%@", [self rootPath], @"output"];
    return op;
}

+(NSString *)outputPathForFileName:(NSString *)fileName
{
    NSString *op = [SF:@"%@/%@", [self outputPath], fileName];
    return op;
}


#pragma mark - Resources
+(NSString *)pathForResourceNamed:(NSString *)resourceName
{
    NSString *extension = [resourceName pathExtension];
    NSInteger trimIndex = resourceName.length - extension.length - 1;
    NSString *name = [resourceName substringToIndex:trimIndex];
    
    // Search for the resource in the main bundle.
    NSString *path = [[NSBundle mainBundle] pathForResource:name
                                                     ofType:extension];
    
    // Return the path of the resource (nil if not found).
    return path;
}

@end
