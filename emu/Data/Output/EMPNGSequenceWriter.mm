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
#import "EMDB.h"
#import "EMDB+Files.h"

#import "HMImageTools.h"
#import "HMImages.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"

@interface EMPNGSequenceWriter() {
//    image_type *resampled_image;
    
    vTime_type firstFrameTimeStamp;
    vTime_type previousFrameTimeStamp;
    vTime_type totalTime;
    vTime_type delta;
    
    vTime_type duration;
    
    BOOL done;
    BOOL canceled;
    
    dispatch_semaphore_t semaphore;
}

@property (nonatomic) NSTimeInterval durationInSeconds;
@property (atomic) NSInteger framesCount;
@property (atomic) NSInteger writtenFramesCount;
@property (nonatomic) NSString *oid;
@property (nonatomic) NSString *path;
@property (nonatomic) NSDate *startTime;


@end

@implementation EMPNGSequenceWriter

#pragma mark - HMWriterProtocol
@synthesize writesFramesOfType = _writesFramesOfType;
@synthesize debugMode = _debugMode;


-(void)prepareWithInfo:(NSDictionary *)info
{
    self.writesFramesOfType = HMWritesFramesOfTypeImageType;
    self.framesCount = 0;
    self.oid = [[NSUUID UUID] UUIDString];
    self.path = [EMDB pathForFootageWithOID:self.oid];
    semaphore = dispatch_semaphore_create(0);
    [EMDB ensureDirPathExists:self.path];
    
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
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSDictionary *info = @{
                           emkPath:self.path,
                           emkOID:self.oid,
                           emkNumberOfFrames:@(self.framesCount),
                           emkDate:[NSDate date],
                           emkDuration:@(self.durationInSeconds),
                           emkDebug:@(self.debugMode)
                           };
    return info;
}

-(void)cancel
{
    canceled = YES;
}

-(void)writeImageTypeFrame:(void *)image
{
    if (done || canceled) {
        return;
    }
    
    image_type *output_image = (image_type *)image;
    vTime_type currentFrameTimeStamp = output_image->timeStamp;
    
    // If first frame, store the time stamp of the first frame.
    if (self.framesCount == 0) {
    
        // The first frame
        firstFrameTimeStamp = currentFrameTimeStamp;

    } else {
        totalTime = currentFrameTimeStamp - firstFrameTimeStamp;
        delta = currentFrameTimeStamp - previousFrameTimeStamp;

        if (totalTime > duration || self.framesCount > MAX_NUMBER_OF_FRAMES) {
            // Done! Skip future frames.
            NSString *logString = [SF:@"Done writing png: %@ frames, time:%@ , expected duration:%@", @(self.framesCount), @(totalTime), @(duration)];
            HMLOG(TAG, EM_DBG, @"%@", logString);
            REMOTE_LOG(@"%@", logString);
            done = YES;
            return;
        }
        
        if (delta < 42000000) return;
    }
    

    // Convert the image passed as image_type to UIImage
    UIImage *uiImage = [HMImageTools createUIImageFromImageType:output_image withAlpha:YES];
    
    // Counting frames
    self.framesCount++;
    NSInteger currentFrameCount = self.framesCount;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        // Save the image in a background queue.
        [HMImages savePNGOfUIImage:uiImage
                     directoryPath:self.path
                          withName:[SF:@"img-%@", @(currentFrameCount)]];
        self.writtenFramesCount++;
        if (self.writtenFramesCount >= currentFrameCount) {
            dispatch_semaphore_signal(semaphore);
        }
    });
    previousFrameTimeStamp = currentFrameTimeStamp;
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
