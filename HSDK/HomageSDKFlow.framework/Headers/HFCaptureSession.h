//
//  HFCaptureSession.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 24/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HFCObject.h"
#import "HFCaptureSessionDelegate.h"
#import "HFProcessingProtocol.h"
#import "HFWriterProtocol.h"
#import "HFCamera.h"
#import <HomageSDKCore/HomageSDKCore.h>

@class HFCameraPreviewView;

/**
 The object controlling the flow of the camera capture and image processing session.

 By default, capture session will use Homage's background removal algorithms for processing frames captured by the camera.
 
 As an optional (advanced) feature, it is possible to replace a different video processing object, 
 as long as it complies to the HFProcessingProtocol.

 Basic work flow with this object for implementing a recorder that supports BG Removal:

 - Create an instance of this object and keep a strong reference to it.
 - (optional) Change any configuration if required.
 - (optional) Set a delegate (usually your UIViewController, or any other object that conforms to HFCaptureSessionDelegate protocol ).
 - (optional) Set a HFCameraView view, so capture session will be able to send processed frames to be displayed to the user in real time.
 
 Some code examples:
 
    // Initialization
    HFCaptureSession *hcf = [HFCaptureSession new];
    hcf.delegate = self;
    hcf.cameraPreviewView = self.someHFCameraViewIBOutlet;
    [hcf setupAndStartCaptureSession];
    self.captureSession = hcf;
 
    .
    .
    .
 
    // Somewhere else in the code, probably as a response to the user pressing a record button in the UI.
    [self.captureSession startRecordingUsingWriter:movieWriter
                                          duration:3.0];
 
    .
    .
    .
 
    // After user pressed a cancel recording button or exited the recorder UI / App
    // while still recording (for example).
    if (self.captureSession.isRecording) {
        [self.captureSession cancelRecording];
    }
 
 */
@interface HFCaptureSession : HFCObject

#pragma mark - Initializations
/**  @name Initializations */

/**
 Initializes the capture session object with default configuration.
 
 The default configuration is:
 
 - Camera will attempt to start capture in 640x480, cropping the image to 480x480 square before processing and displaying result.
 - Capture session will use the background removal algorithm for video processing.
 - Video processing, preview to the user and recording will be of 480x480 square images.
 - The algorithm will use the default contour/silhouette (see: HomageSDKCore -> HCBackground for more info).

 @note:
 This method just calls initForBGRemovalWithPreset:processingResolutionType:processingSilhouetteType:
 
 @return A new instance of capture session with default configuration.
*/
-(instancetype)init;


/**
 Initialization method with more fine control over configuration of the capture session object.

 @param sessionPreset  NSString Pass the preffered AVCaptureSessionPreset... that is the preffered capture resolution mode of the device's camera (see AVFoundation constants for more details)
 @param resolutionType hcbResolution The resolution of the processed frames. If this resolution differs from the resolution of the captured frames, frames will be resized (and cropped if required) to this resolution before being processed.
 @param silhouetteType hcbSilhouetteType the silhouette type used.

 @return A new instance of capture session with provided configuration.
 */
-(instancetype)initForBGRemovalWithPreset:(NSString *)sessionPreset
                 processingResolutionType:(hcbResolution)resolutionType
                 processingSilhouetteType:(hcbSilhouetteType)silhouetteType;

/**
 Initialization method with more fine control over configuration of the capture session object.
 
 @param sessionPreset  NSString Pass the preffered AVCaptureSessionPreset... that is the preffered capture resolution mode of the device's camera (see AVFoundation constants for more details)
 @param resolutionType hcbResolution The resolution of the processed frames. If this resolution differs from the resolution of the captured frames, frames will be resized (and cropped if required) to this resolution before being processed.
 @param silhouetteType hcbSilhouetteType the silhouette type used.
 @param bgImage UIImage image to replace the background with (used for camera preview etc).
 
 @return A new instance of capture session with provided configuration.
 */
-(instancetype)initForBGRemovalWithPreset:(NSString *)sessionPreset
                 processingResolutionType:(hcbResolution)resolutionType
                 processingSilhouetteType:(hcbSilhouetteType)silhouetteType
                                 bgImage:(UIImage *)bgImage;



/**
 *  The capture session delegate.
 *  @see: HFCaptureSessionDelegate
 */
@property (weak, nonatomic) id<HFCaptureSessionDelegate> delegate;

#pragma mark - Life Cycle
/**  @name Life cycle */

/**
 *  Call this to start the capture session (after finishing configuration and setting the delegate).
 */
-(void)setupAndStartCaptureSession;


/**
 *  Call this to release the capture / camera feed stack and release related objects / memory.
 */
-(void)stopAndTearDownCaptureSession;


#pragma mark - State
/**  @name State */

/**
 *  Indicates if HFCaptureSession will control the flow and state of the capture session automatically.
 *  By default this is set to YES.
 *  To turn off automatic flow, an explicit call to stopAutoFlow needs to be made, but this is not needed in most use cases.
 */
@property (atomic, readonly) BOOL automaticFlow;

/**
 *  Current processing state (read only)
 */
@property (atomic, readonly) HFProcessingState processingState;

/**
 *  Set a manual change to a new video processing state.
 *  This method raises an exception if automaticFlow is set to YES.
 *
 *  @param state HFProcessingState the state to change to.
 *  @param info  NSDictionary extra info.
 */
-(void)setProcessingState:(HFProcessingState)state info:(NSDictionary *)info;

/**
 *  Stop automatic flow. Call this only if you need to control the flow of the capture session manually in an external object.
 *  In most use cases this shouldn't be used and you should let HFCaptureSession control its own flow and state.
 */
-(void)stopAutoFlow;

/**
 *  Resets the state and turns on the automatic flow handling of the session.
 *  (sets state to idle and sets automaticFlow to YES)
 */
-(void)resetAndStartAutoFlow;

/**
 *  Force to continue to the processing frames state.
 *
 *  By default (when automaticFlow is YES/true) the session
 *  will only continue from the inspection state to the processing state
 *  when the good background threshold is satisfied.
 *  It is possible to force the change to the processing stage even on bad
 *  background, using a call to this method.
 *
 *  If the session is not in the inspecting state, call to this method will be ignored.
 */
-(void)continueAnyway;

#pragma mark - Camera
/**  @name Camera */

/**
 *  The HFCamera object.
 */
@property (nonatomic, readonly) HFCamera *camera;

/**
 *  The HFCameraPreviewView object. Used to display the camera feed (and processed frames preview) to the user.
 */
@property (nonatomic) HFCameraPreviewView *cameraPreviewView;


/**
 *  Switch to the other camera of the device (if available).
 */
-(void)switchCamera;

#pragma mark - Inputs

/**
 *  AVCaptureVideoOrientation the orientation of the device while capturing the video.
 */
@property (readwrite) AVCaptureVideoOrientation referenceOrientation;

/**
 *  Frame rate of the capture (TODO: check if required)
 */
@property (readonly) Float64 videoFrameRate;

/**
 *  The dimensions of the video capture.
 */
@property (readonly) CMVideoDimensions videoDimensions;

/**
 *  The CMVideoCodecType of this capture.
 */
@property (readonly) CMVideoCodecType videoType;

#pragma mark - Recording
/**  @name Recording */

/**
 *  Start recording captured frames to a file (or files) using the passed writer.
 *
 *  @param writer   The writer object conforming to the HMWriterProtocol.
 *  @param duration The max duration of the recording.
 *         If you are not interested in an automatic finish of the recording
 *         set the duration to be 0. When set to 0, recording will need to be
 *         stopped manually by calling the stopRecording method.
 */
-(void)startRecordingUsingWriter:(id<HFWriterProtocol>)writer
                        duration:(NSTimeInterval)duration;

/**
 *  Cancel recording and delete all temp files.
 */
-(void)cancelRecording;

/**
 *  Stop the recording and close output files if required.
 *  will happen automatically if reached the positive duration set in
 *  startRecordingUsingWriter:duration:
 */
-(void)stopRecording;

/**
 *  YES if currently recording.
 */
@property(atomic, readonly) BOOL isRecording;


/**
 *  Indication if it is OK to call startRecordingUsingWriter:duration:
 *
 *  @return BOOL indicating if it is allowed to start a new recording.
 */
-(BOOL)mayStartRecording;

/**
 *  YES if may call startRecordingWithWriter:info:
 *  NO if the capture session is in a state that doesn't allow starting a new recording.
 *  @note will return NO when capture session is recording.
 */
@property(readonly) BOOL mayStartRecording;

#pragma mark - Debugging
/**  @name Debugging */

/**
 * debugOutput - 0 by default for normal behaviour. Set to 1(mask) or 2(original) for changing the default output (used for debugging).
 */
@property (atomic) NSInteger debugOutput;

@end
