//
//  HMCaptureSession.h
//  homage sdk
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"HMCaptureSession"
#define CS_ERROR_DOMAIN @"Capture session error domain"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HMCaptureSession.h"
#import "HMVideoProcessingProtocol.h"
#import "HMCaptureSessionError.h"
#import "AppManagement.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"
#import "ImageMark/ImageMark.h"
#import "Utime/GpTime.h"

#define BYTES_PER_PIXEL 4

@interface HMCaptureSession ()

@property (nonatomic) NSString *captureSessionUUID;

@property (nonatomic) NSInteger extractCounter;

// Video feed
@property (nonatomic) BOOL shouldDropAllFrames;
@property (readwrite) Float64 videoFrameRate;
@property (readwrite) CMVideoDimensions videoDimensions;
@property (readwrite) CMVideoCodecType videoType;
@property (readwrite) AVCaptureVideoOrientation videoOrientation;

// Video processing
@property (atomic, readwrite) id<HMVideoProcessingProtocol> videoProcessor;
@property (atomic, readwrite) HMVideoProcessingState videoProcessingState;

// Recording
@property (readwrite, getter=isRecording) BOOL recording;
@property (nonatomic) id<HMWriterProtocol> writer;
@property (nonatomic) NSTimeInterval duration;

// UUID
@property (nonatomic) NSString *uuid;

@end

@implementation HMCaptureSession

@synthesize videoFrameRate, videoDimensions, videoType;
@synthesize referenceOrientation;
@synthesize videoOrientation;
@synthesize recording;
@synthesize extractCounter;

#pragma mark - Initializations
-(id)init
{
    if (self = [super init]) {
        previousSecondTimestamps = [[NSMutableArray alloc] init];
        referenceOrientation = AVCaptureVideoOrientationPortrait;
        backgroundDetectionEnabled = NO;
        extractCounter = 0;
        self.shouldDropAllFrames = NO;
        self.uuid = [[NSUUID UUID] UUIDString];
        HMLOG(TAG, EM_DBG, @"Started capture session %@", self.uuid);
    }
    return self;
}

-(void)dealloc
{
    HMLOG(TAG, EM_DBG, @"Dealloc capture session %@", self.uuid);    
}

#pragma mark - Observers handlers
-(void)onCaptureSessionRuntimeError:(NSNotification *)notification
{
}

#pragma mark - Camera
-(void)switchCamera
{
//    AVCaptureDevicePosition currentPosition = videoIn.device.position;
//    AVCaptureDevicePosition otherPosition = currentPosition == AVCaptureDevicePositionFront? AVCaptureDevicePositionBack: AVCaptureDevicePositionFront;
//    
//    // First check that the device support the alternative position.
//    AVCaptureDevice *otherCamera = [self videoDeviceWithPosition:otherPosition];
//    if (otherCamera == nil) return;
//    
//    // We have the other camera, lets switch to it.
//    [captureSession beginConfiguration];
//    [captureSession removeInput:videoIn];
//    NSError *error;
//    videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:otherCamera error:&error];
//    [captureSession addInput:videoIn];
//    [captureSession commitConfiguration];
}



-(void)cameraLockedFocus
{
    CGPoint point = CGPointMake(0.5, 0.5);
    [self cameraLockedFocusOnPoint:point];
}

-(void)cameraLockedFocusOnPoint:(CGPoint)point
{
    AVCaptureDevice *device = [videoIn device];
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        
        // Lock focus on point of interest.
        if ([device isFocusPointOfInterestSupported] &&
            [device isFocusModeSupported:AVCaptureFocusModeLocked]) {
            
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeLocked;
        }
        
        // Lock exposure point to the point of interest.
        if ([device isExposurePointOfInterestSupported] &&
            [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeLocked;
        }
        
        // Lock white balance
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeLocked;
        }
        
        // Disable monitoring of subject area changes.
        [device setSubjectAreaChangeMonitoringEnabled:NO];
        
        // Done with configuring the cam.
        [device unlockForConfiguration];
    } else {
        HMLOG(TAG, EM_ERR, @"Failed preparing camera for video processing.");
    }
}

-(void)cameraUnlockedFocus
{
    CGPoint point = CGPointMake(0.5, 0.5);
    [self cameraUnlockedFocusOnPoint:point];
}

-(void)cameraUnlockedFocusOnPoint:(CGPoint)point
{
    AVCaptureDevice *device = [videoIn device];
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        
        // Auto focus on point of interest.
        if ([device isFocusPointOfInterestSupported] &&
            [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        // Auto exposure on point of interest,
        if ([device isExposurePointOfInterestSupported] &&
            [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        // Auto white balance
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
        
        // Disable monitoring of subject area changes.
        [device setSubjectAreaChangeMonitoringEnabled:YES];
        
        // Done with configuring the cam.
        [device unlockForConfiguration];
    } else {
        HMLOG(TAG, EM_ERR, @"Failed preparing camera for video processing.");
    }
}

-(void)refocusOnPoint:(CGPoint)point inspectFrame:(BOOL)inspectFrame
{
    [self cameraLockedFocusOnPoint:point];
    
}

-(void)autoFocusOnPoint:(CGPoint)point
{
    [self cameraUnlockedFocusOnPoint:point];
}


#pragma mark - capture session
- (void)setupAndStartCaptureSession
{
    // Create a shallow queue for buffers going to the display for preview.
    OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault,
                                       1,
                                       CMBufferQueueGetCallbacksForUnsortedSampleBuffers(),
                                       &previewBufferQueue);

    if (err) {
        // TODO: Handle errors here
    }
    
    // Create serial queue for movie writing
    movieWritingQueue = AppManagement.sh.ioQueue;
    
    // If capture session not set up yet, set it up.
    if ( !captureSession )
        [self setupCaptureSession];
    
    // If capture session is not running yet, start running.
    if ( !captureSession.isRunning )
        [captureSession startRunning];
}

-(BOOL)setupCaptureSession
{
    /*
	 * Create capture session
	 */
    captureSession = [AVCaptureSession new];
    captureSession.sessionPreset = self.prefferedSessionPreset;
    
	/*
	 * Create video connection
	 */
    AVCaptureDevice *camera = [self videoDeviceWithPosition:AVCaptureDevicePositionFront];
    videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:nil];
    
    if ([captureSession canAddInput:videoIn])
        [captureSession addInput:videoIn];

	AVCaptureVideoDataOutput *videoOut = [AVCaptureVideoDataOutput new];
	/*
     Discard late video frames early in the capture pipeline, since its
     processing can take longer than real-time on some platforms (such as iPhone 3GS).
     Clients whose image processing is faster than real-time should consider setting AVCaptureVideoDataOutput's
     alwaysDiscardsLateVideoFrames property to NO.
	 */
	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
    NSDictionary *videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
	[videoOut setVideoSettings:videoSettings];
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];

    if ([captureSession canAddOutput:videoOut])
		[captureSession addOutput:videoOut];
    
	videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
	self.videoOrientation = [videoConnection videoOrientation];

	return YES;
}

#pragma mark - Audio capture device
- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if (devices.count > 0) {
        return devices[0];
    }
    
    // No capture devices found.
    return nil;
}

#pragma mark - Video capture device
-(AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position)
            return device;
    }
    
    // No device found that match position.
    return nil;
}

#pragma mark - Capture
-  (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    if (self.shouldDropAllFrames) return;
    
    CMSampleBufferRef processedSampleBuffer = nil;

    // The video processing state.
    HMVideoProcessingState state = self.videoProcessingState;
    
    // Should inpect the frame?
    BOOL thisFrameShouldBeInspected = (state == HMVideoProcessingStateInspectFrames ||
                                       state == HMVideoProcessingStateInspectSingleNextFrameAndProcessFrames ||
                                       state == HMVideoProcessingStateInspectAndProcessFrames) &&
                                        (extractCounter % 15 == 0);
    if (state == HMVideoProcessingStateInspectSingleNextFrameAndProcessFrames) {
        // HMVideoProcessingStateInspectSingleNextFrameAndProcessFrames
        // ==> HMVideoProcessingStateProcessFrames
        [self setVideoProcessingState:HMVideoProcessingStateProcessFrames];
        state = self.videoProcessingState;
    }

    
    // Count frames
    extractCounter++;
    
    // Should process the frame?
    BOOL thisFrameShouldBeProcessed = state == HMVideoProcessingStateProcessFrames ||
                                        state == HMVideoProcessingStateInspectAndProcessFrames;

    if ( connection == videoConnection ) {
        
        if (self.videoProcessor) {

            // 1. Prepare the frame (crop / resize according to settings)
            [self.videoProcessor prepareFrame:sampleBuffer];
            
            // 2. Process the frame with the set video processor
            //    (only if currently should be processing frames)
            if (thisFrameShouldBeProcessed) {
                // Process and returns the processedSampleBuffer that is used for display.
                // processFrame method may also store an output image
                // (implementation of the video processor needs to store that image
                // on the movieWritingQueue, and writing that image also must
                // look at that image on the movieWritingQueue).
                processedSampleBuffer = [self.videoProcessor processFrame:sampleBuffer];
            } else {
                processedSampleBuffer = sampleBuffer;
            }

            // 3. Once every few frames, inspect the frame if required.
            if (thisFrameShouldBeInspected) {
                // SampleBuffer to PixelBuffer
                [self.videoProcessor inspectFrame];
            }
        }
        
        // Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
		// we'll drop this frame for preview (this keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, processedSampleBuffer);
		if ( !err ) {
			dispatch_async(dispatch_get_main_queue(), ^{
                CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                if (sbuf) {
                    CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self.sessionDisplayDelegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
                }
			});
        }
    }
    
    // If we processed a sample buffer using the video processor,
    // we already enqueued the processed sample buffer for display.
    // We don't need it anymore so we can release it.
    if (_videoProcessor &&
        connection == videoConnection &&
        processedSampleBuffer &&
        thisFrameShouldBeProcessed) {
        CFRelease(processedSampleBuffer);
    }

    // If should be recording and a writer was set
    // pass the latest output frame to the writer, on the movie writing queue.
    if (movieWritingQueue) {
        dispatch_async(movieWritingQueue, ^{
            
            if (recording && self.writer) {
                image_type *output =(image_type *)[self.videoProcessor latestOutputImage];
                [self.writer writeImageTypeFrame:output];
                
                // If reached duration or max number of frames, stop recording
                // and finish up.
                if (self.writer.shouldFinish) {
                    [self _stopRecording];
                    
                    // Stop video processing for this session.
                    [self setVideoProcessingState:HMVideoProcessingStateIdle];
                }
            }
        });
    }
}


-(void)initializeVideoProcessor:(id<HMVideoProcessingProtocol>)videoProcessor
{
    self.videoProcessor = videoProcessor;
    if (movieWritingQueue) {
        videoProcessor.outputQueue = movieWritingQueue;
    }
}

#pragma mark Utilities
-(void)calculateFramerateAtTimestamp:(CMTime) timestamp
{
	[previousSecondTimestamps addObject:[NSValue valueWithCMTime:timestamp]];
    
	CMTime oneSecond = CMTimeMake( 1, 1 );
	CMTime oneSecondAgo = CMTimeSubtract( timestamp, oneSecond );
    
	while( CMTIME_COMPARE_INLINE( [[previousSecondTimestamps objectAtIndex:0] CMTimeValue], <, oneSecondAgo ) )
		[previousSecondTimestamps removeObjectAtIndex:0];
    
	Float64 newRate = (Float64) [previousSecondTimestamps count];
	self.videoFrameRate = (self.videoFrameRate + newRate) / 2;
}

#pragma mark - Capture session
- (void)stopAndTearDownCaptureSession
{
    //
    // Cleaning up!
    //
    self.shouldDropAllFrames = YES;
    
    // Stopping the capture session.
    if (captureSession) {
        [captureSession stopRunning];
        captureSession = nil;
    }

    // releasing the camera preview buffer queue
    if (previewBufferQueue) {
        CFRelease(previewBufferQueue);
        previewBufferQueue = NULL;
    }
    
    // releasing the writing queue
    if (movieWritingQueue) {
        movieWritingQueue = NULL;
    }
    
    // releasing the video processor (if exists)
    if (self.videoProcessor) {
        self.videoProcessingState = HMVideoProcessingStateIdle;
        self.videoProcessor = nil;
    }
    
    videoConnection = nil;
}

#pragma mark - Video Processing
-(void)setVideoProcessingState:(HMVideoProcessingState)state info:(NSDictionary *)info
{
    // Set the state
    self.videoProcessingState = state;
    
    // Reset stuff
    extractCounter = 0;
    [self.videoProcessor cleanUp];
}


#pragma mark - Recording
//
// Start
//
-(void)startRecordingUsingWriter:(id<HMWriterProtocol>)writer
                        duration:(NSTimeInterval)duration
{
    dispatch_async(movieWritingQueue, ^{
        [self _startRecordingUsingWriter:writer
                                duration:duration];
    });
}

-(void)_startRecordingUsingWriter:(id<HMWriterProtocol>)writer
                         duration:(NSTimeInterval)duration
{
    // Validate state.
    if (self.writer || self.recording) {
        // Session in wrong state.
        // Recording should fail.
        HMCaptureSessionError *error = [[HMCaptureSessionError alloc] initWithErrorType:HMCSErrorTypeWrongState
                                                                           errorMessage:@"Failed to start recording. Capture session in wrong state"
                                                                               userInfo:nil];
        
        [self.sessionDelegate recordingDidFailWithError:error];
        return;
    }
    
    // Start a new recording session
    self.writer = writer;
    self.duration = duration;
    [self.writer prepareWithInfo:@{@"duration":@(duration)}];
    self.recording = YES;
    
    // Debugging
    if ([self.sessionDelegate isCaptureSessionDebuggingModeEnabled]) {
        if ([self.videoProcessor respondsToSelector:@selector(startDebugSession)]) {
            [self.videoProcessor startDebugSession];
        }
    }
    
    // Tell delegate that recording did start
    // (communincates this to the delegate on the main thread)
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sessionDelegate recordingDidStartWithInfo:nil];
    });
}

//
// Stop
//
-(void)stopRecording
{
    dispatch_async(movieWritingQueue, ^{
        [self _stopRecording];
    });
}

-(void)_stopRecording
{
    // Validate state.
    if (self.writer == nil || !self.recording) {
        HMCaptureSessionError *error = [[HMCaptureSessionError alloc] initWithErrorType:HMCSErrorTypeWrongState
                                                                           errorMessage:@"Recording failed on stop. Capture session in wrong state"
                                                                               userInfo:nil];
        [self.sessionDelegate recordingDidFailWithError:error];
        return;
    }
    
    // Finish up current recording session.
    self.recording = NO;
    NSDictionary *info = [self.writer finishReturningInfo];
    self.writer = nil;

    // Debugging
    if ([self.sessionDelegate isCaptureSessionDebuggingModeEnabled]) {
        if ([self.videoProcessor respondsToSelector:@selector(finishDebuSessionWithInfo:)]) {
            [self.videoProcessor finishDebuSessionWithInfo:info];
        }
    }

    // Tell the delegate that the recording session ended,
    // on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sessionDelegate recordingDidStopWithInfo:info];
    });
}

//
// Cancel
//
-(void)cancelRecording
{
    dispatch_async(movieWritingQueue, ^{
        // Validate state.
        if (self.writer == nil || self.recording) {
            HMCaptureSessionError *error = [[HMCaptureSessionError alloc] initWithErrorType:HMCSErrorTypeWrongState
                                                                               errorMessage:@"Recording failed on stop. Capture session in wrong state"
                                                                                   userInfo:nil];
            [self.sessionDelegate recordingDidFailWithError:error];
            return;
        }
        
        // Finish up current recording session.
        self.recording = NO;
        [self.writer cancel];
        self.writer = nil;
    });
}

@end