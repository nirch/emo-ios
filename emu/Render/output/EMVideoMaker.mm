//
//  EMVideoMaker.m
//  emu
//
//  Created by Aviv Wolf on 5/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMVideoMaker.h"
#import "Gpw/Vtool/Vtool.h"
#import "AppManagement.h"
#import "EMNotificationCenter.h"

@interface EMVideoMaker() {
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
    CMTime currFrameTime;
    CMTime timePerFrame;

    CFMutableArrayRef _pbArray;
    
    dispatch_queue_t _renderingQueue;
    
    NSInteger _fDirection;
    NSInteger _fCurrIndex;
    NSInteger _fCount;
    NSInteger _fLoopCount;
}

@property BOOL preparedForWriting;

@property BOOL finishedWritingVideo;
@property BOOL finishedAddingAudio;

@end


@implementation EMVideoMaker

@synthesize steamedWriting = _steamedWriting;
@synthesize fxLoops = _fxLoops;
@synthesize audioFileURL = _audioFileURL;


#pragma mark - Pixel buffer arrays
void PixelBufferArrayReleaseCallback(CFAllocatorRef allocator, const void* value)
{
    if (value != NULL) {
        CVPixelBufferRef pb = (CVPixelBufferRef)value;
        CVPixelBufferRelease(pb);
    }
}
const CFArrayCallBacks pbArrayCallBacks = {0, 0, PixelBufferArrayReleaseCallback, 0, 0};


#pragma mark - Initialization
-(instancetype)init
{
    self = [super init];
    if (self) {
        _fxLoops = 0;
        _steamedWriting = YES;
        _preparedForWriting = NO;
        _pbArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &pbArrayCallBacks);
        _finishedWritingVideo = NO;
        _finishedAddingAudio = NO;
        _audioFileURL = nil;
        CFRetain(_pbArray);
    }
    return self;
}

#pragma mark - Video output effects
-(void)setFxLoops:(NSInteger)fxLoops
{
    assert(_fxLoops==0);
    _fxLoops = fxLoops;
    _steamedWriting = NO;
}

-(void)setFxPingPong:(BOOL)fxPingPong
{
    _fxPingPong = fxPingPong;
}

#pragma mark - Prepare for writing
-(void)prepareForWriting:(NSError **)error
{
    // ================
    //      Video
    // ================
    
    NSInteger numPixels = self.dimensions.width * self.dimensions.height;
    NSInteger bitsPerSecond = numPixels * self.bitsPerPixel;

    // Initialize asset writer
    NSError *writerInitError = NULL;
    assetWriter = [AVAssetWriter assetWriterWithURL:self.videoOutputURL fileType:AVFileTypeMPEG4 error:&writerInitError];
    // Check for errors.
    if (writerInitError) {
        // TODO: error handling.
        *error = writerInitError;
        return;
    }
    
    // Check if can be configured properly.
    NSDictionary *videoCompressionSettings = @{
                                               AVVideoCodecKey: AVVideoCodecH264,
                                               AVVideoWidthKey: @(self.dimensions.width),
                                               AVVideoHeightKey: @(self.dimensions.height),
                                               AVVideoCompressionPropertiesKey: @{
                                                       AVVideoAverageBitRateKey: @(bitsPerSecond),
                                                       AVVideoMaxKeyFrameIntervalKey: @(self.fps)
                                                       }
                                               };
    if (![assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        NSLog(@"Couldn't apply output settings to asset  writer");
        // TODO: error handling.
        return;
    }

    // Configure output settings
    assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    
    if (![assetWriter canAddInput:assetWriterVideoInput]) {
        NSLog(@"Couldn't add asset writer video input.");
        // TODO: error handling.
        return;
    }
    
    // Add input.
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput
                                                                                                   sourcePixelBufferAttributes:nil];
    [assetWriter addInput:assetWriterVideoInput];
    
    // First frame time.
    currFrameTime = CMTimeMake(0, 1000);
    timePerFrame = CMTimeMake(1000 / self.fps, 1000);
}

#pragma mark - Adding frames
-(void)addImageFrame:(image_type *)image;
{
    // If not prepared for writing, prepare for writing first.
    if (!self.preparedForWriting) {
        NSError *error = NULL;
        [self prepareForWriting:&error];
        if (error) {
            // TODO: error handling.
        }
        self.preparedForWriting = YES;
    }
    
    // Write or store the frame.
    if (self.steamedWriting) {
        CVPixelBufferRef pb = CVtool::CVPixelBufferRef_from_image(image);
        [self _writePixelBuffer:pb];
        CVPixelBufferRelease(pb);
    } else {
        [self _storeImageFrame:image];
    }
}

#pragma mark - Writing frames
-(void)_writePixelBuffer:(CVPixelBufferRef)pb
{
    NSError *error;
    if ( assetWriter.status == AVAssetWriterStatusUnknown ) {
        // Start writing if didn't do it before
        if ([assetWriter startWriting]) {
            CMTime startTime = CMTimeMake(0, 1000);
            [assetWriter startSessionAtSourceTime:startTime];
        } else {
            // TODO: error handling
            NSLog(@"Error in creating asset writer: %@", error.description);
        }
    }

    if (assetWriter.status == AVAssetWriterStatusWriting ) {
        while (assetWriterVideoInput.readyForMoreMediaData == NO) {
            NSDate *nextCheck = [NSDate dateWithTimeIntervalSinceNow:0.05];
            [[NSRunLoop currentRunLoop] runUntilDate:nextCheck];
        }
        if ([assetWriterPixelBufferInput appendPixelBuffer:pb withPresentationTime:currFrameTime]) {
            currFrameTime = CMTimeAdd(currFrameTime, timePerFrame);
        } else {
            // TODO: error handling.
        }
    }
}

#pragma mark - Storing frames for later writing
-(void)_storeImageFrame:(image_type *)image
{
    CVPixelBufferRef pb = CVtool::CVPixelBufferRef_from_image(image);
    CFArrayAppendValue(_pbArray, pb);
}


#pragma mark - Finish Up
-(void)finishUp
{
    // If not written using streamed writing,
    // will now write the video using stored frame
    // and finish up only when done writing.
    if (!self.steamedWriting) {
        [self _writeVideoUsingStoredFrames];
    }
    
    // Finishing up writing
    if (assetWriter.status == AVAssetWriterStatusWriting) {
        [assetWriter finishWritingWithCompletionHandler:^{
            // Finale cleanups after finishing writing (if required).
            if (!self.steamedWriting) {
                CFArrayRemoveAllValues(_pbArray);
                CFRelease(_pbArray);
            }
            self.finishedWritingVideo = YES;
        }];
    } else {
        // TODO: error handling.
        NSLog(@"Trying to close a video while not writing?");
    }
    
    // Block until finished.
    while (self.finishedWritingVideo == NO) {
        NSDate *nextCheck = [NSDate dateWithTimeIntervalSinceNow:0.05];
        [[NSRunLoop currentRunLoop] runUntilDate:nextCheck];
    }
    
    // Stitch audio to video file if required.
    if (self.audioFileURL) {
        [self stitchAudioToVideoFile];

        // Block until finished.
        while (self.finishedAddingAudio == NO) {
            NSDate *nextCheck = [NSDate dateWithTimeIntervalSinceNow:0.05];
            [[NSRunLoop currentRunLoop] runUntilDate:nextCheck];
        }
    }
}


#pragma mark - Using stored frames
-(void)_writeVideoUsingStoredFrames
{
    [self _startFrame];
    while ([self _moreFramesAvailable]) {
        CVPixelBufferRef pb = (CVPixelBufferRef)CFArrayGetValueAtIndex(_pbArray, _fCurrIndex);
        [self _writePixelBuffer:pb];
        [self _nextFrame];
    }
}


-(void)_startFrame
{
    _fDirection = 1;
    _fCurrIndex = 0;
    _fCount = CFArrayGetCount(_pbArray);
    _fLoopCount = 0;
}

-(void)_nextFrame
{
    // Advance to next frame.
    _fCurrIndex += _fDirection;
    
    // Check if frame is out of bounds.
    if (_fCurrIndex >= _fCount || _fCurrIndex<0) {
        [self _nextLoop];
    }
}

-(void)_nextLoop
{
    if (self.fxPingPong) {
        _fLoopCount++;
        if (_fDirection>0) {
            _fCurrIndex = _fCount-2;
        } else {
            _fCurrIndex = 1;
        }
        _fDirection*=-1;
    } else {
        _fLoopCount++;
        _fCurrIndex=0;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        float progress = (float)_fLoopCount / (float)_fxLoops;
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIRenderProgressReport
                                                            object:nil
                                                          userInfo:@{@"progress":@(progress)}];
    });
    
}

-(BOOL)_moreFramesAvailable
{
    if (_fLoopCount >= _fxLoops) return NO;
    return YES;
}


#pragma mark - Audio
-(void)setAudioFileURL:(NSURL *)audioFileURL
{
    _audioFileURL = audioFileURL;
}


-(void)stitchAudioToVideoFile
{
    if (self.audioFileURL == nil) return;
    
    // The composition object for mixing audio and video files.
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    
    //
    // The name of the new output mixed video file.
    //
    NSString* originalVideoPath = self.videoOutputURL.path;
    NSString* outputFileWithAudioPath = [originalVideoPath stringByReplacingOccurrencesOfString:@".mp4" withString:@"-ws.mp4"];
    NSURL *outputFileWithAudioURL = [NSURL fileURLWithPath:outputFileWithAudioPath];

    
    //
    // The video asset. Used range: from start to finish.
    //
    CMTime nextClipStartTime = kCMTimeZero;
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:self.videoOutputURL options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    
    //
    // The audio asset. Used range: from defined start time, with the duration defined by video.
    //
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:self.audioFileURL options:nil];
    CMTime startTime = CMTimeMake(self.audioStartTime, 1);
    CMTimeRange audio_timeRange = CMTimeRangeMake(startTime, videoAsset.duration);
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    
    //
    // Export
    //
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.outputURL = outputFileWithAudioURL;
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void ) {
        NSError *error = _assetExport.error;
        if (error == nil) {
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:originalVideoPath error:&error];
            
            if (error == nil)
                [fm moveItemAtPath:outputFileWithAudioPath toPath:originalVideoPath error:&error];
        }
        self.finishedAddingAudio = YES;
    }];
}


@end
