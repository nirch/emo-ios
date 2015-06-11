//
//  HMGreenMachineDebugger.m
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"HMGreenMachineDebugger"

#import "HMGreenMachineDebugger.h"
#import <ZipKit/ZKFileArchive.h>

@interface HMGreenMachineDebugger()

@property NSString *rootDir;
@property NSString *folderPath;
@property NSString *outputName;

@property NSInteger inImageCount;
@property NSInteger outImageCount;

@end

@implementation HMGreenMachineDebugger

NSString* const inFileName = @"in-";
NSString* const outFileName = @"out-";
NSString* const inExt = @".jpg";
NSString* const outExt = @".png";


-(instancetype)init
{
    self = [super init];
    
    if (self) {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // Folder name.
        NSDate *now = [NSDate date];
        NSDateFormatter *f = [NSDateFormatter new];
        f.dateFormat = @"YYYYMM_ddHHmmss";
        
        // Folder path
        self.rootDir = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
        self.outputName = [SF:@"DEBUG_%@",[f stringFromDate:now]];
        self.folderPath = [self.rootDir stringByAppendingPathComponent:self.outputName];
        
        // Create the folder
        [fm createDirectoryAtPath:self.folderPath withIntermediateDirectories:NO
                       attributes:nil error:nil];
    }
    return self;
}


# pragma mark - Debug a frame (original image)
-(void)originalImage:(image_type *)m_original_image
{
    if (self.outputQueue) {
        dispatch_async(self.outputQueue, ^{
            // save image to file
            NSString *imagePath = [SF:@"/%@%04ld",inFileName, (long)++self.inImageCount];
            [HMImageTools saveImageType3Jpeg:m_original_image directoryPath:self.folderPath withName:imagePath compressionQuality:1.0];
        });
    }
}


-(void)finishupWithInfo:(NSDictionary *)info
{
    NSNumber *debugMode = info[@"debug"];
    if (debugMode == nil || ([debugMode boolValue] == NO)) return;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *srcPath = [SF:@"%@/" ,info[@"path"]];
        NSString *destPath = [SF:@"%@/output" ,self.folderPath];
        NSError *error;
        [fm copyItemAtPath:srcPath toPath:destPath error:&error];
        HMLOG(TAG, EM_DBG, @"Error while copying processed images: %@", [error localizedDescription]);
    });
}



@end