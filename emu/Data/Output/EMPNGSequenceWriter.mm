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

#define TAG @"EMPNGSequenceWriter"

#define MAX_NUMBER_OF_FRAMES 150

#import "EMPNGSequenceWriter.h"
#import "EMFiles.h"
#import "EMDB.h"

#import "HMImageTools.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"

@interface EMPNGSequenceWriter() {
    image_type *resampled_image;
    
    vTime_type firstFrameTimeStamp;
    vTime_type totalTime;
    
    vTime_type duration;
    
    BOOL done;
    BOOL canceled;
}

@property (nonatomic) NSTimeInterval durationInSeconds;
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
    
    firstFrameTimeStamp = 0;
    totalTime = 0;
    
    // Duration
    self.durationInSeconds = [info[@"duration"] doubleValue];
    duration = self.durationInSeconds * 1000000000;
    
    // done flag
    done = NO;
    canceled = NO;
}


-(NSDictionary *)finishReturningInfo
{
    NSString *oid = [[NSUUID UUID] UUIDString];
    [EMFiles savePNGSequence:self.pngs toFolderNamed:oid];
    [self clean];
    return @{
             emkOID:oid,
             emkNumberOfFrames:@(self.framesCount),
             emkDate:[NSDate date],
             emkDuration:@(self.durationInSeconds)
             };
}


-(void)cancel
{
    canceled = YES;
    [self clean];
}


-(void)clean
{
    self.pngs = nil;
}


-(void)writeImageTypeFrame:(void *)image
{
    if (done || canceled) {
        return;
    }
    
    image_type *output_image = (image_type *)image;
    resampled_image = image_sample2(output_image, resampled_image);
    
    vTime_type currentFrameTimeStamp = output_image->timeStamp;
    resampled_image->timeStamp = currentFrameTimeStamp;
    
    // HMLOG(TAG, DBG, @"Frame time stamp:%@", @(currentFrameTimeStamp));
    
    // If first frame, store the time stamp of the first frame.
    if (self.framesCount == 0) {
        firstFrameTimeStamp = currentFrameTimeStamp;
    } else {
        totalTime = currentFrameTimeStamp - firstFrameTimeStamp;

        if (totalTime > duration || self.framesCount > MAX_NUMBER_OF_FRAMES) {
            // Done! Skip future frames.
            NSString *logString = [SF:@"Done writing png: %@ frames, time:%@ , expected duration:%@", @(self.framesCount), @(totalTime), @(duration)];
            HMLOG(TAG, EM_DBG, @"%@", logString);
            REMOTE_LOG(@"%@", logString);
            done = YES;
            return;
        }
    }
    
    NSLog(@">>>> XXX %@ %@", @(self.framesCount), @(totalTime));
    
    // Counting frames
    self.framesCount++;

    // Convert the image passed as image_type to UIImage.
    UIImage *png = [HMImageTools createUIImageFromImageType:resampled_image withAlpha:YES];
    [self.pngs addObject:png];
}


-(void)writePixelBufferFrame:(CMSampleBufferRef)sampleBuffer
{
    [NSException raise:NSInvalidArgumentException
                format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
}

-(BOOL)shouldFinish
{
    return done;
}

-(BOOL)wasCanceled
{
    return canceled;
}

@end
