//
//  HMImages.m
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMImages.h"

@implementation HMImages

#pragma mark - Saving UIImage
+(void)saveJPEGOfUIImage:(UIImage *)image
                withName:(NSString *)name
      compressionQuality:(CGFloat)compressionQuality
{
    NSData *imageData = UIImageJPEGRepresentation(image, compressionQuality);
    [self saveData:imageData fileName:name extension:@"jpg"];
}

+(void)savePNGOfUIImage:(UIImage *)image
               withName:(NSString *)name
{
    NSData *imageData = UIImagePNGRepresentation(image);
    [self saveData:imageData fileName:name extension:@"png"];
}

+(void)savePNGOfUIImage:(UIImage *)image
          directoryPath:(NSString *)directoryPath
               withName:(NSString *)name
{
    NSData *imageData = UIImagePNGRepresentation(image);
    [self saveData:imageData
     directoryPath:directoryPath
          fileName:name
         extension:@"png"];
}

+(void)saveData:(NSData *)imageData
       fileName:(NSString *)fileName
      extension:(NSString *)extension
{
    [self saveData:imageData
     directoryPath:nil
          fileName:fileName
         extension:extension];
}

+(void)saveData:(NSData *)imageData
  directoryPath:(NSString *)directoryPath
       fileName:(NSString *)fileName
      extension:(NSString *)extension
{
    // If no directory path passed, use the documents folder.
    if (directoryPath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        directoryPath = documentsDirectory;
    }
    
    // Build the path
    NSString *path = [NSString stringWithFormat:@"%@.%@" , fileName, extension];
    NSString *dataPath = [directoryPath stringByAppendingPathComponent:path];
    
    // Write to file.
    [imageData writeToFile:dataPath atomically:YES];
}


@end
