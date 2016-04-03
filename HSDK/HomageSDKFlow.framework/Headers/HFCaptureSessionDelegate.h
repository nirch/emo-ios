//
//  HFCaptureSessionDelegate.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 24/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HFProcessingProtocol.h"

/**
 *  The protocol defining the capture session delegate.
 *
 *  Used for reporting events and errors from the capture session to the (optional) delegate object.
 *
 *  Useful for passing your UIViewContoller as a delegate to the capture session object.
 *  Allow to update the state of the UI according to the changing states or errors in the capture session object.
 */
@protocol HFCaptureSessionDelegate <NSObject>

@required

#pragma mark - Camera
/**  @name Camera */

/**
 *  The session is reporting that it is using the given camera position.
 *
 *  @param position - AVCaptureDevicePosition indicating if front/back camera.
 */
-(void)sessionUsingCameraPosition:(AVCaptureDevicePosition)position;

#pragma mark - State changes and info

/**
 *  The session state updated from a state to a new state.
 *
 *  @param fromState The previous state of the session.
 *  @param toState   The new state of the session.
 */
-(void)sessionUpdatedFromState:(HFProcessingState)fromState toState:(HFProcessingState)toState;

#pragma mark - Recording
/**  @name Recording */

/**
 *  Recording did start.
 *
 *  @param info Extra info about the recording.
 */
- (void)recordingDidStartWithInfo:(NSDictionary *)info;

/**
 *  Recording will stop.
 *  Called when the capture should stop (when capture duration ended or when stopRecording was called explicitly).
 *  If capture session does not need to post process the capture, recordingDidStopWithInfo: will follow immediatly.
 *  If capture session do need to post process the capture, recordingIsPostProcessingWithProgress:info: will be called
 *  continously while progress is being made with the post process and recordingDidStopWithInfo: will be called
 *  when the post processing is done.
 *
 *  @param info Extra info about the recording.
 */
- (void)recordingWillStopWithInfo:(NSDictionary *)info;

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

/**
 *  Recording is post processing the a finished recording, reporting progress to the delegate.
 *
 *  @param progress CGFloat a progress value (0.0 - 1.0) of the post process progress.
 *  @param info     NSDictionary info about the recording.
 */
-(void)recordingPostProcessingWithProgress:(CGFloat)progress
                                      info:(NSDictionary *)info;

@optional
#pragma mark - Debugging
/**  @name Debugging */

/**
 *  Returns if the capture session should be in debug mode or not.
 *
 *  @return YES if debug mode enabled, NO otherwise.
 */
-(BOOL)isCaptureSessionDebuggingModeEnabled;


@end
