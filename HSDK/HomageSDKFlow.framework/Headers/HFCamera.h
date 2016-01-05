//
//  HFCamera.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 02/12/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HFCObject.h"
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  Helper class for setting and using the device's camera/s.
 *  Used by the HFCaptureSession class.
 */
@interface HFCamera : HFCObject

/**
 *  Preffered camera device position.
 */
@property (nonatomic) AVCaptureDevicePosition prefferedDevicePosition;

/**
 *  The currently used capture device input.
 */
@property (nonatomic, readonly) AVCaptureDevice *currentCaptureDevice;

/**
 * Switch to the other camera (if available) in the middle of an active session.
 */
-(void)switchCamera;

/**
 * Lock focus+exposure on point 0.5,0.5 (center)
 */
-(void)cameraLockedFocus;

/**
 * Unlock the focus+exposure and auto focus on point 0.5,0.5 (center).
 */
-(void)cameraUnlockedFocus;

/**
 * Auto Refocus+exposure camera on a given normalized point.
 *
 *  @param point            A normalized CGPoint (coord values 0.0 - 1.0) to refocus on.
 */
-(void)autoFocusOnPoint:(CGPoint)point;

@end
