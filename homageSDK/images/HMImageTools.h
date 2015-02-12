//
//  HMImageTools.h
//  emo
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "Gpw/Vtool/Vtool.h"
#import "MattingLib/UniformBackground/UniformBackground.h"

@interface HMImageTools : NSObject


#pragma mark - Converting to UIImage
/**
 *  Given an image_type object, creates and returns a UIImage object.
 *
 *  @param image image_type object, with the following assumptions:
 *      - bitsPerPixel = 32
 *      - bitsPerComponent = 8
 *      - 4 channels (rgba)
 *
 *  @return newly created UIImage object. 
 *
 *      Creates image with the following settings:
 *
 *          bitmap info = kCGBitmapByteOrderDefault | kCGImageAlphaLast
 *          color space = CGColorSpaceCreateDeviceRGB
 *          
 */
+(UIImage *)createUIImageFromImageType:(image_type *)image;

#pragma mark - Saving UIImage

/**
 *  Converts a UIImage object to it's JPEG data represenstation and saves it to disk.
 *
 *  @param image A UIImage object
 *  @param name  The name of the output file saved to disk (just the name, no extension)
 *  @param compressionQuality The quality of the compression. Value in the range [0.0 ... 1.0]
 */
+(void)saveJPEGOfUIImage:(UIImage *)image
                withName:(NSString *)name
      compressionQuality:(CGFloat)compressionQuality;

/**
 *  Converts a UIImage object to it's PNG data represenstation and saves it to disk.
 *
 *  @param image A UIImage object
 *  @param name  The name of the output file saved to disk (just the name, no extension)
 */
+(void)savePNGOfUIImage:(UIImage *)image
               withName:(NSString *)name;

/**
 *  Save the data of an NSData object to disk. No assumptions on the content of the data made.
 *  The file will be saved atomically (saved to a temp file and on finish/success renamed to the final name).
 *
 *  @param imageData An NSData object.
 *  @param fileName  The name of the output file saved to disk.
 *  @param extension The extension name of the file.
 */
+(void)saveData:(NSData *)imageData
       fileName:(NSString *)fileName
      extension:(NSString *)extension;

#pragma mark - Saving image_type

/**
 *  Save an image_type object with 3 channels as PNG file.
 *
 *  @param image3 The image_type object (3 channels) that will be converted to UIImage and saved as PNG.
 *  @param name   The name of the output file (not including extension name).
 */
+(void)saveImageType3:(image_type *)image3
             withName:(NSString *)name;

/**
 *  Save an image_type object with 4 channels (RGBA) as PNG file.
 *
 *  @param image4 The image_type object (4 channels) that will be converted to UIImage and saved as PNG.
 *  @param name   The name of the output file (not including extension name).
 */
+(void)saveImageType4:(image_type *)image4
             withName:(NSString *)name;

@end
