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
#import "HMVideoProcessingProtocol.h"
#import "HMWriterProtocol.h"

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
    
//    // Writing
//	AVAssetWriter *assetWriter;
//	AVAssetWriterInput *assetWriterAudioIn;
//	AVAssetWriterInput *assetWriterVideoIn;
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

#pragma mark - Video Processing
// Video processing (optional)
-(void)initializeVideoProcessor:(id<HMVideoProcessingProtocol>)videoProcessor;

// Change to a new video processing state
@property (atomic, readonly) HMVideoProcessingState videoProcessingState;
-(void)setVideoProcessingState:(HMVideoProcessingState)state info:(NSDictionary *)info;

#pragma mark - Recording

/**
 *  Start recording captured frames to a file (or files) using the passed writer.
 *
 *  @param writer   The writer object conforming to the HMWriterProtocol.
 *  @param duration The max duration of the recording. 
 *         If you are not interested in an automatic finish of the recording
 *         set the duration to be 0. When set to 0, recording will need to be
 *         stopped manually.
 */
-(void)startRecordingUsingWriter:(id<HMWriterProtocol>)writer
                        duration:(NSTimeInterval)duration;

/**
 *  Cancel recording and delete all temp files.
 */
-(void)cancelRecording;

/**
 *  Stop the recording and close output files if required.
 *  will happen automatically if reached duration set in 
 *  startRecordingToFile:duration:error:
 */
-(void)stopRecording;

/**
 *  YES if currently recording.
 */
@property(readonly, getter=isRecording) BOOL recording;


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
 *  Recording did start.
 *
 *  @param info Extra info about the recording.
 */
- (void)recordingDidStartWithInfo:(NSDictionary *)info;


/**
 *  Recording did stop with info.
 *
 *  @param info Extra info about the recording.
 */
- (void)recordingDidStopWithInfo:(NSDictionary *)info;


/**
 *  Recording did stop with info.
 *
 *  @param info Extra info about the recording.
 */
- (void)recordingWasCanceledWithInfo:(NSDictionary *)info;


/**
 *  Recording did fail, returning an error.
 *
 *  @param error The error causing the recording to fail.
 */
-(void)recordingDidFailWithError:(NSError *)error;

@end
