//
//  EMFiles.m
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFiles.h"
#import "HMImages.h"

@implementation EMFiles


+(NSString *)docsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
}

+(NSString *)outputPath
{
    NSString *op = [SF:@"%@/%@", [self docsPath], @"output"];
    return op;
}

+(void)ensureOutputPathExists
{
    [self createDirectoryNamed:@"output"];
}

+(NSString *)outputPathForFileName:(NSString *)fileName
{
    NSString *op = [SF:@"%@/%@", [self outputPath], fileName];
    return op;
}

+(NSString *)createDirectoryNamed:(NSString *)directoryName
{
    // Get the paths
    NSString *docsPath = [EMFiles docsPath];
    NSString *dirPath = [docsPath stringByAppendingPathComponent:[SF:@"/%@", directoryName]];

    // Create the directory.
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dirPath])
        [fm createDirectoryAtPath:dirPath
      withIntermediateDirectories:NO
                       attributes:nil error:nil];
    
    return dirPath;
}


+(NSURL *)urlForBundledResourceNamed:(NSString *)resourceName
                       withExtension:(NSString *)extension
{
    return [[NSBundle mainBundle] URLForResource:resourceName
                                   withExtension:extension];
}


+(NSString *)pathForResourceNamed:(NSString *)resourceName
{
    NSString *extension = [resourceName pathExtension];
    NSInteger trimIndex = resourceName.length - extension.length - 1;
    NSString *name = [resourceName substringToIndex:trimIndex];
    NSString *path = [[NSBundle mainBundle] pathForResource:name
                                                     ofType:extension];
    
    return path;
}

//+(NSString *)outputPath
//{
//    NSString *path = [EMFiles createDirectoryNamed:@"output"];
//}

@end
