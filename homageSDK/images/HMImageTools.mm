//
//  HMImageTools.m
//  emu
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMImageTools.h"

@implementation HMImageTools

#pragma mark - UIImage
+(UIImage *)createUIImageFromImageType:(image_type *)imageData
{
    // Get the data
    unsigned char *pixels        = imageData->data;
    
    // Info about the image.
    int size = imageData->width * imageData->height * 4;
    size_t width                    = imageData->width;
    size_t height                   = imageData->height;
    size_t bitsPerComponent         = 8;
    size_t bitsPerPixel             = 32;
    size_t bytesPerRow              = imageData->width * 4;
    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo         = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
    
    // Creation of a new CGImage object.
    NSData* newPixelData = [NSData dataWithBytes:pixels length:size];
    CFDataRef imgData = (__bridge CFDataRef)newPixelData;
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(imgData);
    CGImageRef newImageRef = CGImageCreate (
                                            width,
                                            height,
                                            bitsPerComponent,
                                            bitsPerPixel,
                                            bytesPerRow,
                                            colorspace,
                                            bitmapInfo,
                                            imgDataProvider,
                                            NULL,
                                            NO,
                                            kCGRenderingIntentDefault
                                            );
    
    // Crate the new UIImage with the CGImage and release the CGImage.
    UIImage *newImage   = [[UIImage alloc] initWithCGImage:newImageRef];
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(imgDataProvider);
    CGImageRelease(newImageRef);
    
    // Return the newly created UIImage object.
    return newImage;
}

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

#pragma mark - Saving image_type
+(void)saveImageType3:(image_type *)image3 withName:(NSString *)name
{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *imageToSave = [self createUIImageFromImageType:image4];
    [self savePNGOfUIImage:imageToSave withName:name];
}

+(void)saveImageType4:(image_type *)image4 withName:(NSString *)name
{
    UIImage *imageToSave = [self createUIImageFromImageType:image4];
    [self savePNGOfUIImage:imageToSave withName:name];
}

@end
