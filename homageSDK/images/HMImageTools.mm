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
    int channelsCount = imageData->channel;
    int size = imageData->width * imageData->height * channelsCount;
    size_t width                    = imageData->width;
    size_t height                   = imageData->height;
    size_t bitsPerComponent         = 8;
    size_t bitsPerPixel             = bitsPerComponent * channelsCount;
    size_t bytesPerRow              = imageData->width * channelsCount;
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


+(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(UIImage *)image:(UIImage *)sourceImage scaledProportionallyToSize:(CGSize)targetSize
{
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage ;
}

@end
