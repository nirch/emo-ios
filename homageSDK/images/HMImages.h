//
//  HMImages.h
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@interface HMImages : NSObject

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
 *  Converts a UIImage object to it's PNG data represenstation and saves it to disk.
 *
 *  @param image A UIImage object
 *  @param name  The name of the output file saved to disk (just the name, no extension)
 */
+(void)savePNGOfUIImage:(UIImage *)image
          directoryPath:(NSString *)directoryPath
               withName:(NSString *)name;


/**
 *  Save the data of an NSData object to disk. No assumptions on the content of the data made.
 *  The file will be saved atomically (saved to a temp file and on finish/success renamed to the final name).
 *  The file is saved to the user's documents folder.
 *
 *  @param imageData An NSData object.
 *  @param fileName  The name of the output file saved to disk.
 *  @param extension The extension name of the file.
 */
+(void)saveData:(NSData *)imageData
       fileName:(NSString *)fileName
      extension:(NSString *)extension;

/**
 *  Save the data of an NSData object to disk. No assumptions on the content of the data made.
 *  The file will be saved atomically (saved to a temp file and on finish/success renamed to the final name).
 *  The file is saved to the user's documents folder.
 *
 *  @param imageData An NSData object.
 *  @param directoryPath The directory path string, indicating where to save the file.
 *  @param fileName  The name of the output file saved to disk.
 *  @param extension The extension name of the file.
 */
+(void)saveData:(NSData *)imageData
  directoryPath:(NSString *)directoryPath
       fileName:(NSString *)fileName
      extension:(NSString *)extension;


@end
