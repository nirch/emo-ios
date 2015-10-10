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
 *  Instanciate a new recorder with some provided configuration info.
 *
 *  @param info     Configuration info, defining the flow of the recorder.
 *
 *      Possible configurations:
 *          @{emkFirstTake:@YES, emkEmuticonDefOID:"...", emkEmuticonDefName: "..."} - onboarding
 *          @{emkRetakeAll:@YES} - The recorder will do a new retake for all emus.
 *          @{emkRetakePackageOID:@"..."} - The recorder will retake all emus in a pack.
 *          @{emkRetakeEmuticonsOID:@[@"",@"",...]} - The recorder will retake emus in the list of OIDs.
 *          Otherwise: will just add a new take to the list of user takes.
 *
 *  @return A new EMRecorderVC instance.
 */
+(EMRecorderVC *)recorderVCWithConfigInfo:(NSDictionary *)info;

@property (nonatomic) EMRecorderFlowType flowType;

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

