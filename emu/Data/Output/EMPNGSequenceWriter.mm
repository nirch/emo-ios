//
//  HMPNGSequenceWriter.m
//  emu
//
//  Converts a series of frames received as image_type (4 channels)
//  scales them down to half the size
//  and stores them in the user footage managed object.
//
//  Created by Aviv Wolf on 2/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPNGSequenceWriter.h"

#import "HMImageTools.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"

@interface EMPNGSequenceWriter() {
    image_type *resampled_image;
    vTime_type previousTimeStamp;
    vTime_type deltaTimeStamp;
}


@property (nonatomic) NSMutableArray *pngs;
@property (nonatomic) NSInteger framesCount;

@end

@implementation EMPNGSequenceWriter

#pragma mark - HMWriterProtocol
@synthesize writesFramesOfType = _writesFramesOfType;
@synthesize outputPathURL = _outputPathURL;
@synthesize outputFileName = _outputFileName;


-(void)prepareWithInfo:(NSDictionary *)info
{
    self.writesFramesOfType = HMWritesFramesOfTypeImageType;
    self.framesCount = 0;
    self.pngs = [NSMutableArray new];
}


-(NSDictionary *)finishReturningInfo
{
    NSString *oid = [[NSUUID UUID] UUIDString];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create a new user footage object.
        
        
        [self clean];
    });
    return @{@"oid":oid};
}


-(void)cancel
{
    [self clean];
}


-(void)clean
{
    self.pngs = nil;
}


-(void)writeImageTypeFrame:(void *)image
{
    image_type *output_image = (image_type *)image;
    resampled_image = image_sample2(output_image, resampled_image);
    resampled_image->timeStamp = output_image->timeStamp;
    
    // Get time passed since previous framce
    vTime_type t = resampled_image->timeStamp;
    if (previousTimeStamp > 0) {
        deltaTimeStamp = t - previousTimeStamp;
    }
    previousTimeStamp = t;
    
    // Build the output url for the png.
    self.framesCount++;
    
    // Convert the image passed as image_type to UIImage.
    //NSString *pngName = [self frameNameForIndex:self.framesCount];
    //UIImage *png = [HMImageTools createUIImageFromImageType:resampled_image];
    
}


-(void)writePixelBufferFrame:(CMSampleBufferRef)sampleBuffer
{
    [NSException raise:NSInvalidArgumentException
                format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
}


@end
