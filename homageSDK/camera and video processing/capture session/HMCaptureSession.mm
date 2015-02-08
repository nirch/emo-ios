//
//  HMCaptureSession.h
//  homage sdk
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"HMCaptureSession"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HMCaptureSession.h"
#import "HMVideoProcessingProtocol.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"
#import "ImageMark/ImageMark.h"
#import "Utime/GpTime.h"

#define BYTES_PER_PIXEL 4

@interface HMCaptureSession ()

@property (nonatomic) NSInteger extractCounter;

// Redeclared as readwrite so that we can write to the property and still
// be atomic with external readers.
@property (readwrite) Float64 videoFrameRate;
@property (readwrite) CMVideoDimensions videoDimensions;
@property (readwrite) CMVideoCodecType videoType;
@property (readwrite, getter=isRecording) BOOL recording;
@property (readwrite) AVCaptureVideoOrientation videoOrientation;


// Video processor
@property (nonatomic) id<HMVideoProcessingProtocol> videoProcessor;
//@property (nonatomic) image_type *m_original_image;

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
        [self initObservers];
    }
    return self;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onCaptureSessionRuntimeError:)
                     name:AVCaptureSessionRuntimeErrorNotification
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:nil];
}

#pragma mark - Observers handlers
-(void)onCaptureSessionRuntimeError:(NSNotification *)notification
{
}

#pragma mark - capture session
- (void)setupAndStartCaptureSession
{
    // Create a shallow queue for buffers going to the display for preview.
    OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);

    if (err) {
        // TODO: Handle errors here
    }
    
    // Create serial queue for movie writing
    movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    if ( !captureSession )
        [self setupCaptureSession];
    
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
	 * Create audio connection
	 */
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    if ([captureSession canAddInput:audioIn])
        [captureSession addInput:audioIn];

	AVCaptureAudioDataOutput *audioOut = [AVCaptureAudioDataOutput new];
	dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
	[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];

    if ([captureSession canAddOutput:audioOut])
		[captureSession addOutput:audioOut];
	audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];

	/*
	 * Create video connection
	 */
    videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionFront] error:nil];
    
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
	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMSampleBufferRef processedSampleBuffer = nil;
    extractCounter++;
    
    BOOL thisFrameShouldBeProcessed = _shouldProcessVideoFrames;
    BOOL thisFrameShouldBeInspected = _shouldInspectVideoFrames && (extractCounter % 13 == 0);

    if ( connection == videoConnection ) {
		// Get framerate
		CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		[self calculateFramerateAtTimestamp:timestamp];

		// Get frame dimensions (for onscreen display)
		if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
			self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );

		// Get buffer type
		if ( self.videoType == 0 )
			self.videoType = CMFormatDescriptionGetMediaSubType( formatDescription );
        
        
        if (self.videoProcessor) {
            //
            // 1. Prepare the frame (crop / resize according to settings)
            //
            [self.videoProcessor prepareFrame:sampleBuffer];
            
            //
            // 2. Process the frame with the set video processor
            //    (only if currently should be processing frames)
            //
            if (thisFrameShouldBeProcessed) {
                processedSampleBuffer = [self.videoProcessor processFrame:sampleBuffer];
            } else {
                processedSampleBuffer = sampleBuffer;
            }

            //
            // 3. Once every few frames, inspect the frame if required.
            //
            if (thisFrameShouldBeInspected) {
                // SampleBuffer to PixelBuffer
                [self.videoProcessor inspectFrame];
                // HMLOG(TAG, VERBOSE, @"total frames captured: %@", @(extractCounter));
            }
        }
        
        
        
        // Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
		// we'll drop this frame for preview (this keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, processedSampleBuffer);
		if ( !err ) {
			dispatch_async(dispatch_get_main_queue(), ^{
				//CVPixelBufferRef pixBuf = (CVPixelBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                if (sbuf) {
                    CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self.sessionDisplayDelegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
                }
			});
        }
    }

    CFRetain(sampleBuffer);
    CFRetain(formatDescription);
    
    dispatch_async(movieWritingQueue, ^{

        if ( assetWriter ) {

//            BOOL wasReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//
//            if (connection == videoConnection) {
//
//                // Initialize the video input if this is not done yet
//                if (!readyToRecordVideo)
//                {
//                    CMFormatDescriptionRef processedFormatDesc = CMSampleBufferGetFormatDescription(processedSampleBuffer);
//                    readyToRecordVideo = [self setupAssetWriterVideoInput:processedFormatDesc];
//                }
//
//                // Write video data to file
//                if (readyToRecordVideo && readyToRecordAudio)
//                {
//                    //[self saveSampleBuffer:processedSampleBuffer withName:@"beforewriting"];
//                    CVPixelBufferRef processedPixelBuffer = CMSampleBufferGetImageBuffer(processedSampleBuffer);
//                    CVPixelBufferRetain(processedPixelBuffer);
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo withPixelBuffer:processedPixelBuffer];
//                    CVPixelBufferRelease(processedPixelBuffer);
//                }
//            }
//            else if (connection == audioConnection) {
//
//                // Initialize the audio input if this is not done yet
//                if (!readyToRecordAudio)
//                    readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
//
//                // Write audio data to file
//                if (readyToRecordAudio && readyToRecordVideo)
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio withPixelBuffer:nil];
//            }
//
//            BOOL isReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//            if ( !wasReadyToRecord && isReadyToRecord ) {
//                recordingWillBeStarted = NO;
//                self.recording = YES;
//                [self.delegate recordingDidStart];
//            }
            
        }
        CFRelease(sampleBuffer);
        CFRelease(formatDescription);

        if (_videoProcessor &&
            connection == videoConnection &&
            processedSampleBuffer &&
            thisFrameShouldBeProcessed) {
            CFRelease(processedSampleBuffer);
        }
    });
}

-(void)initializeVideoProcessor:(id<HMVideoProcessingProtocol>)videoProcessor
{
    self.videoProcessor = videoProcessor;
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
    if (captureSession) {
        [captureSession stopRunning];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:captureSession];
        captureSession = nil;
    }

    if (previewBufferQueue) {
        CFRelease(previewBufferQueue);
        previewBufferQueue = NULL;
    }
    if (movieWritingQueue) {
        movieWritingQueue = NULL;
    }
}

-(void)prepareCameraStateForVideoProcessing
{
    dispatch_async(movieWritingQueue, ^{
        CGPoint point = CGPointMake(100,100);
        AVCaptureDevice *device = [videoIn device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeLocked])
            {
                [device setFocusMode:AVCaptureFocusModeLocked];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeLocked])
            {
                [device setExposureMode:AVCaptureExposureModeLocked];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:false];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

@end