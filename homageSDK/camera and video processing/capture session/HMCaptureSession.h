/*
  HMCaptureSession.h
  homage sdk
 
  Capture session:

    An api for the initialization, tearing down and
    controlling the camera and audio inputs.
    Also takes care of sav
    
    No image processing is performed in this class.
 
    On initialization, an instance of an image processing class
    (conforming to the video processor protocol) can be passed and will be used
    while recording.

  Copyright (c) 2015 Homage. All rights reserved.
*/

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>

@protocol HMCaptureSessionDisplayDelegate;
@protocol HMCaptureSessionDelegate;
@protocol HMVideoProcessingProtocol;

@interface HMCaptureSession : NSObject <
    AVCaptureAudioDataOutputSampleBufferDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
>
{
    // Session and connections
    AVCaptureSession *captureSession;
    AVCaptureConnection *audioConnection;
    AVCaptureConnection *videoConnection;

    // Video feed
    AVCaptureDeviceInput *videoIn;
	NSMutableArray *previousSecondTimestamps;
	Float64 videoFrameRate;
	CMVideoDimensions videoDimensions;
	CMVideoCodecType videoType;
    BOOL backgroundDetectionEnabled;

    // Buffer queue
    CMBufferQueueRef previewBufferQueue;
    
    // Writing
	AVAssetWriter *assetWriter;
	AVAssetWriterInput *assetWriterAudioIn;
	AVAssetWriterInput *assetWriterVideoIn;
	dispatch_queue_t movieWritingQueue;
    
    // Orientation
	AVCaptureVideoOrientation referenceOrientation;
	AVCaptureVideoOrientation videoOrientation;
    
	// Should only be accessed on movie writing queue
    BOOL readyToRecordAudio; 
    BOOL readyToRecordVideo;
	BOOL recordingWillBeStarted;
	BOOL recordingWillBeStopped;
	BOOL recording;
    BOOL processingVideoFrames;
}

#pragma mark - session
@property (nonatomic) NSString *prefferedSessionPreset;
@property (nonatomic) CGSize prefferedSize;

// Capture session display delegate
@property (weak, nonatomic) id <HMCaptureSessionDisplayDelegate> sessionDisplayDelegate;

// Capture session delegate
@property (weak, nonatomic) id <HMCaptureSessionDelegate> sessionDelegate;

// Setup
-(void)setupAndStartCaptureSession;
-(void)stopAndTearDownCaptureSession;

#pragma mark - Inputs
// Inputs
@property (readwrite) AVCaptureVideoOrientation referenceOrientation;
@property (readonly) Float64 videoFrameRate;
@property (readonly) CMVideoDimensions videoDimensions;
@property (readonly) CMVideoCodecType videoType;
@property (readonly) BOOL processingVideoFrames;

// puase and resume session
//-(void)pauseCaptureSession; // Pausing while a recording is in progress will cause the recording to be stopped and saved.
//-(void)resumeCaptureSession;

#pragma mark - Recording
// Recording
//- (void) startRecording;
//- (void) stopRecording;
@property(readonly, getter=isRecording) BOOL recording;


// Output
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferIn;


#pragma mark - Video processing
// Video processing (optional)
-(void)initializeVideoProcessor:(id<HMVideoProcessingProtocol>)videoProcessor;

@end


#pragma mark - HMCaptureSessionDisplayDelegate
@protocol HMCaptureSessionDisplayDelegate <NSObject>
// ---------------------------------
// Capture session display delegate.
// ---------------------------------

@required
/**
 *  Called on the main thread when a pixel buffer is ready to be displayed.
 */
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer;

@end

#pragma mark - HMCaptureSessionDelegate
// --------------------------------
// Capture session delegate.
// --------------------------------
@protocol HMCaptureSessionDelegate <NSObject>

@required
/**
 *  Recording is about to start.
 */
- (void)recordingWillStart;

/**
 *  Recording did start.
 */
- (void)recordingDidStart;

/**
 *  Recording will stop.
 */
- (void)recordingWillStop;

/**
 *  Recording did stop.
 */
- (void)recordingDidStop;

@end
