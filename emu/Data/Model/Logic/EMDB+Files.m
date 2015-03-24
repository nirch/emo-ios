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
    [self createDirectoryNamed:@"resources"];
    [self createDirectoryNamed:@"temp"];
}


#pragma mark - general paths and files creation
+(NSURL *)rootURL
{
    // Now using a group container (so keyboard and app can share resources and data)
    NSURL *groupURL = [[NSFileManager defaultManager]
                       containerURLForSecurityApplicationGroupIdentifier:
                       GROUP_CONTAINER_IDENTIFIER];
    return groupURL;
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
//    return [NSURL URLWithString:basePath];
}

+(NSString *)rootPath
{
    NSURL *url = [self rootURL];
    return [url path];
}


+(NSString *)createDirectoryNamed:(NSString *)directoryName
{
    // Get the paths
    NSString *dirPath = [self pathForDirectoryNamed:directoryName];
    
    // Create the directory if missing.
    [self ensureDirPathExists:dirPath];
    
    return dirPath;
}

+(NSString *)pathForDirectoryNamed:(NSString *)directoryName
{
    NSString *rootPath = [EMDB rootPath];
    NSString *dirPath = [rootPath stringByAppendingPathComponent:[SF:@"/%@", directoryName]];
    return dirPath;
}


+(BOOL)ensureDirPathExists:(NSString *)dirPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![self pathExists:dirPath]) {
        
        // Create missing directory.
        [fm createDirectoryAtPath:dirPath
      withIntermediateDirectories:NO
                       attributes:nil
                            error:nil];
        
    }
    return [self pathExists:dirPath];
}

+(BOOL)pathExists:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
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
    return [self pathForResourceNamed:resourceName path:nil];
}

+(NSString *)pathForResourceNamed:(NSString *)resourceName path:(NSString *)path
{
    NSString *rp;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *extension = [resourceName pathExtension];
    NSInteger trimIndex = resourceName.length - extension.length - 1;
    NSString *name = [resourceName substringToIndex:trimIndex];

    // Search for the resource in a given local path
    if (path) {
        rp = [SF:@"%@/%@", path, resourceName];
        if ([fm fileExistsAtPath:rp]) return rp;
    }
    
    // Search for the resource in the main bundle.
    rp = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    
    // Return the path of the resource (nil if not found).
    return rp;
}

@end
