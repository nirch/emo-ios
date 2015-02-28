//
//  ViewController.h
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecorderDelegate.h"

typedef NS_ENUM(NSInteger, EMRecorderState) {
    EMRecorderStateStarting                         = 0,
    EMRecorderStateBGDetectionShouldStart           = 1,
    EMRecorderStateBGDetectionInProgress            = 2,
    EMRecorderStateFGExtractionShouldStart          = 3,
    EMRecorderStateFGExtractionInProgress           = 4,
    EMRecorderStateShouldStartRecording             = 5,
    EMRecorderStateRecording                        = 6,
    EMRecorderStateFinishingUp                      = 7,
    EMRecorderStateReviewPreview                    = 8,
    EMRecorderStateDone                             = 9,
    EMRecorderStateFatalError                       = 10
};

@class HMCaptureSession;

@interface EMRecorderVC : UIViewController

/**
 *  Instanciate a new recorder for the provided flow.
 *
 *  @param flowType The flow type of the recorder (see EMRecorderFlowType)
 *  @param info     Extra info provided to the recorder when presented.
 *
 *  @return A new EMRecorderVC instance.
 */
+(EMRecorderVC *)recorderVCForFlow:(EMRecorderFlowType)flowType
                              info:(NSDictionary *)info;

@property (nonatomic) EMRecorderFlowType flowType;

#define emkPackage @"package"
#define emkEmuticon @"emuticon"
@property (nonatomic) NSDictionary *info;

@property (weak, nonatomic) id<EMRecorderDelegate>delegate;

#pragma mark - Onboarding
@property (nonatomic, readonly) BOOL shouldPresentOnBoarding;

#pragma mark - Capture session
@property (nonatomic, readonly) HMCaptureSession *captureSession;
@property (nonatomic) NSTimeInterval recordingDuration;

#pragma mark - States
@property (readonly) EMRecorderState recorderState;


@end

