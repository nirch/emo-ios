/**/

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>

@protocol HMCaptureSessionDelegate;

@interface HMCaptureSession : NSObject <
    AVCaptureAudioDataOutputSampleBufferDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
>
{  
    AVCaptureDeviceInput *videoIn;
	NSMutableArray *previousSecondTimestamps;
	Float64 videoFrameRate;
	CMVideoDimensions videoDimensions;
	CMVideoCodecType videoType;

	AVCaptureSession *captureSession;
	AVCaptureConnection *audioConnection;
	AVCaptureConnection *videoConnection;
	CMBufferQueueRef previewBufferQueue;
	
	NSURL *movieURL;
	AVAssetWriter *assetWriter;
	AVAssetWriterInput *assetWriterAudioIn;
	AVAssetWriterInput *assetWriterVideoIn;
	dispatch_queue_t movieWritingQueue;
    
    
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

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation;

- (void) showError:(NSError*)error;

- (void) setupAndStartCaptureSession;
- (void) stopAndTearDownCaptureSession;

- (void) startRecording;
- (void) stopRecording;

- (void) pauseCaptureSession; // Pausing while a recording is in progress will cause the recording to be stopped and saved.
- (void) resumeCaptureSession;
- ( void ) initGreenMachine;

@end


#pragma mark - HMCaptureSessionDelegate
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
