//
//  ViewController.h
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class HMCaptureSession;

@interface EMRecorderVC : UIViewController

// The video capture session
@property (strong, nonatomic, readonly) HMCaptureSession *captureSession;

@end

