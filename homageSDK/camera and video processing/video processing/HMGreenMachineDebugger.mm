//
//  HMGreenMachineDebugger.m
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"HMGreenMachineDebugger"

#import "HMGreenMachineDebugger.h"
#import <zipzap/zipzap.h>
#import "ZZArchive.h"

@interface HMGreenMachineDebugger()

@property NSString *tempFilePath;
@property int totalImages;

@end

@implementation HMGreenMachineDebugger

NSString* const zipFolderName = @"emu_debug.zip";
NSString* const pathToImagesFolder = @"emu_debug_files";
NSString* const imageFileName = @"im-";
NSString* const imageExt = @".jpg";

-(instancetype)init
{
    self = [super init];
    
    if (self) {
        // set file path to images folder
        self.tempFilePath = [SF:@"%@%@", NSTemporaryDirectory(), pathToImagesFolder];
        
        // delete previous folder if exists
        [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:nil];
        
        // create new images folder
        [self createDirectory:self.tempFilePath];
    }
    return self;
}

-(void)createDirectory:(NSString *)directoryName
{
    
    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryName
                              withIntermediateDirectories:YES
                                               attributes:nil                                                                   error:&error];
}


-(NSString *)getImageName:(int)i
{
    return [SF:@"/%@%04d",imageFileName, i];
}


# pragma mark - Debug a frame (original image)
-(void)originalImage:(image_type *)m_original_image
{
    if (self.outputQueue) {
        dispatch_async(self.outputQueue, ^{
            // Set image name
            NSString *imagePath = [self getImageName:++self.totalImages];
            NSLog(@"totalImages: %d", self.totalImages);
            
            // save image to file
            [HMImageTools saveImageType3Jpeg:m_original_image directoryPath:self.tempFilePath withName:imagePath compressionQuality:1.0];
            NSLog(@"Saved Image: %@/%@%@", self.tempFilePath, [self getImageName:self.totalImages], imageExt);
        });
    }

}


#pragma mark - Zip it
// Zip all the images previously saved to disk
-(void)zipLatestImages{
    // zipping of images
    
    // create zip folder path
    NSString *zipFolderPath = [SF:@"%@%@", NSTemporaryDirectory(), zipFolderName];
    
    // create the archive for the zipped files
    ZZArchive* newArchive = [[ZZArchive alloc] initWithURL:[NSURL fileURLWithPath:zipFolderPath]
                                                   options:@{ZZOpenOptionsCreateIfMissingKey : @YES}
                                                     error:nil];
    
    // set first image path
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[SF:@"%@/%@%@",pathToImagesFolder, [self getImageName:1], imageExt]];
    // set filename of first image
    NSString *filename = [SF:@"%@/%@%@",pathToImagesFolder, [self getImageName:1], imageExt];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    if (fileExists) {
        // create archive and zip first image
        [newArchive updateEntries:
         @[
           [ZZArchiveEntry archiveEntryWithFileName:filename
                                           compress:YES
                                          dataBlock:^(NSError** error)
            {
                // return the data of the image
                NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                return data;
            }]
           ]
                            error:nil];
    }
    
    for (int i = 2; i < self.totalImages; i++) {
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        
        if (fileExists) {
            // get filepath of image
            filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[SF:@"%@/%@%@",pathToImagesFolder, [self getImageName:i], imageExt]];
            
            // set filename of image
            filename = [SF:@"%@/%@%@",pathToImagesFolder, [self getImageName:i], imageExt];
            
            // update archive adding new images
            ZZArchive* oldArchive = [ZZArchive archiveWithURL:[NSURL fileURLWithPath:zipFolderPath]
                                                        error:nil];
            [oldArchive updateEntries:
             [oldArchive.entries arrayByAddingObject:
              [ZZArchiveEntry archiveEntryWithFileName:filename
                                              compress:YES
                                             dataBlock:^(NSError** error)
               {
                   // return the data of the image
                   NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                   return data;
               }]]
                                error:nil];
        }
    }
    
    
    // reset image count
    self.totalImages = 0;
    
    // Post the notification with the zip file.
    NSDictionary *info = @{@"debug zipped folder":zipFolderPath};
    [[NSNotificationCenter defaultCenter] postNotificationName:hmkDebuggingFinishedZippingFiles
                                                        object:nil
                                                      userInfo:info];
    
}


@end