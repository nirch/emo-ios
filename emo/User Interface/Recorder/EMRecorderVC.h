//
//  ViewController.h
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

typedef NS_ENUM(NSInteger, EMRecorderState) {
    EMRecorderStateStarting                         = 0,
    EMRecorderStateBGDetectionShouldStart           = 1,
    EMRecorderStateBGDetectionInProgress            = 2,
    EMRecorderStateFGExtractionShouldStart          = 3,
    EMRecorderStateFGExtractionInProgress           = 4,
    EMRecorderStateRecordingCountDown               = 5,
    EMRecorderStateRecording                        = 6,
    EMRecorderStateDone                             = 7
};

@class HMCaptureSession;

@interface EMRecorderVC : UIViewController

// TODO: remove this. Used for debugging.
@property (weak, nonatomic) IBOutlet UIImageView *gaga;

#pragma mark - Onboarding
@property (nonatomic, readonly) BOOL shouldPresentOnBoarding;

#pragma mark - Capture session
@property (nonatomic, readonly) HMCaptureSession *captureSession;

#pragma mark - BG FeedBack
-(void)hideBGFeedBackAnimated:(BOOL)animated;
-(void)showBGFeedBackAnimated:(BOOL)animated;

#pragma mark - States
@property (readonly) EMRecorderState recorderState;


@end

