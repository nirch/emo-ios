//
//  HMImageTools.m
//  emu
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMImageTools.h"
#import "HMImages.h"

@implementation HMImageTools

#pragma mark - UIImage
+(UIImage *)createUIImageFromImageType:(image_type *)imageData withAlpha:(BOOL)withAlpha
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
    
    CGBitmapInfo bitmapInfo;
    if (withAlpha) {
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
    } else {
        bitmapInfo = kCGBitmapByteOrderDefault;
    }
    
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

#pragma mark - Saving image_type
+(void)saveImageType3:(image_type *)image3 withName:(NSString *)name
{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *imageToSave = [self createUIImageFromImageType:image4 withAlpha:NO];
    [HMImages savePNGOfUIImage:imageToSave withName:name];
}

+(void)saveImageType4:(image_type *)image4 withName:(NSString *)name
{
    UIImage *imageToSave = [self createUIImageFromImageType:image4 withAlpha:YES];
    [HMImages savePNGOfUIImage:imageToSave withName:name];
}


+(void)saveImageType3Jpeg:(image_type *)image3
            directoryPath:(NSString *)directoryPath
                 withName:(NSString *)name
       compressionQuality:(CGFloat)compressionQuality

{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *imageToSave = [self createUIImageFromImageType:image4 withAlpha:NO];
    [HMImages saveJPEGOfUIImage:imageToSave directoryPath:directoryPath withName:name compressionQuality:compressionQuality];
}

+(void)saveImageType4:(image_type *)image4
            directoryPath:(NSString *)directoryPath
                 withName:(NSString *)name
{
    UIImage *imageToSave = [self createUIImageFromImageType:image4 withAlpha:YES];
    [HMImages savePNGOfUIImage:imageToSave
                 directoryPath:directoryPath
                      withName:name];
}


@end
