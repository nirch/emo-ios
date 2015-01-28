/**/

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>

@protocol HMCaptureSessionDelegate;

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
    
	// Only accessed on movie writing queue
    BOOL readyToRecordAudio; 
    BOOL readyToRecordVideo;
	BOOL recordingWillBeStarted;
	BOOL recordingWillBeStopped;
	BOOL recording;
}

@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferIn;

@property (readwrite, assign) id <HMCaptureSessionDelegate> delegate;

@property (readonly) Float64 videoFrameRate;
@property (readonly) CMVideoDimensions videoDimensions;
@property (readonly) CMVideoCodecType videoType;

@property (readwrite) AVCaptureVideoOrientation referenceOrientation;

@property(readonly, getter=isRecording) BOOL recording;

// Setup
-(void)setupAndStartCaptureSession;
-(void)stopAndTearDownCaptureSession;

// Start and stop recording
//- (void) startRecording;
//- (void) stopRecording;

// puase and resume session
//-(void)pauseCaptureSession; // Pausing while a recording is in progress will cause the recording to be stopped and saved.
//-(void)resumeCaptureSession;

@end


#pragma mark - HMCaptureSessionDelegate
// --------------------------------
// Capture session delegate.
// --------------------------------
@protocol HMCaptureSessionDelegate <NSObject>

@required
/**
 *  Called on the main thread when a pixel buffer is ready to be displayed.
 */
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer;

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
