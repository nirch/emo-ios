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

+(void)savePNGSequence:(NSArray *)pngs toFolderNamed:(NSString *)folderName
{
    // Create a new folder under the cache directory.
    NSString *path = [EMFiles createDirectoryNamed:folderName];
    
    NSInteger i = 0;
    for (UIImage *png in pngs) {
        i++;
        [HMImages savePNGOfUIImage:png
                     directoryPath:path
                          withName:[SF:@"img-%@", @(i)]];
    }
}


@end
