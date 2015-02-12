/*
 
 This is the main view controller of the recorder.

 It has some child view controllers, each controlling a specific part of the UI and flow:
 
    1 - EMOnboardingVC *onBoardingVC
        
        Used when the recorder is initialized with shouldPresentOnBoarding = YES.
        Controls the flow of the onboarding messages and flow when the user opens
        the app for the first time. Allows the user to learn how to shoot videos
        with FG extraction and also return to a previous stage in the flow.
 
    2 - EMPreviewVC *previewVC
 
        A simple view controller owning the custom GL preview view.
        Used to present the video feed (after being processed by the green machine).
 
    3 - EMBGFeedBackVC *bgFeedBackVC
 
        
 
 
 
 */
#define TAG @"RecorderVC"

#import "HMSDK.h"

#import "EMRecorderVC.h"
#import "EMPreviewVC.h"
#import "EMBGFeedBackVC.h"
#import "EMOnboardingVC.h"
#import "EMControlsBarVC.h"
#import "EMRecordButton.h"

@interface EMRecorderVC () <
    HMCaptureSessionDelegate,
    EMOnboardingDelegate,
    EMRecorderControlsDelegate
>

@property (weak, nonatomic) IBOutlet UIView *guiUserControls1Container;
@property (weak, nonatomic) IBOutlet UIView *guiUserControls2Container;
@property (weak, nonatomic) IBOutlet UIView *guiBGFeedBackContainer;
@property (weak, nonatomic) IBOutlet EMRecordButton *guiRecordButton;






// Onboarding
@property (nonatomic, readwrite) BOOL shouldPresentOnBoarding;

// The video capture session
@property (strong, nonatomic, readwrite) HMCaptureSession *captureSession;

// The preview
@property (weak) IBOutlet UIView *guiPreviewCover;
@property (weak) EMPreviewVC *previewVC;

// Background detection feedback
@property (weak) EMBGFeedBackVC *bgFeedBackVC;

// Onboarding
@property (weak) EMOnboardingVC *onBoardingVC;

// User controls
@property (weak) EMControlsBarVC *controlsVC;

// Recorder states
@property (readwrite) EMRecorderState recorderState;


@end

@implementation EMRecorderVC

-(id)awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    self = [super awakeAfterUsingCoder:aDecoder];
    if (self) {
        // Implement initialization with on boarding disabled.
        self.shouldPresentOnBoarding = YES;
    }
    return self;
}

#pragma mark - VC life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initializations
    [self initState];
    [self initCaptureSession];
    [self initVideoProcessing];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Observers
    [self initObservers];
    
    // Start the flow of the recorder.
    [self handleState];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self removeObservers];
}

#pragma mark - Initializations
-(void)initGUI
{
    self.view.backgroundColor = [UIColor clearColor];
    self.guiPreviewCover.alpha = 1;
    [self hideRecordButtonAnimated:NO];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onBackgroundDetectionInfo:)
                     name:hmkNotificationBGDetectionInfo
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkNotificationBGDetectionInfo];
}

#pragma mark - Observers handlers
-(void)onBackgroundDetectionInfo:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    CGFloat weight = [info[hmkInfoBGMarkWeight] floatValue];
    self.bgFeedBackVC.goodBackgroundWeight = weight;
    [self.controlsVC updateBackgroundInfo:info];
    
    if (info[hmkInfoGoodBGSatisfied]) {
        // Good background threshold was satisfied!
        [self handleStateWithInfo:@{hmkInfoGoodBGSatisfied:@YES}];
    }
}

#pragma mark - VC preferences
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed preview segue"]) {
        
        // The preview view controller.
        self.previewVC = segue.destinationViewController;

    } else if ([segue.identifier isEqualToString:@"embed bg feedback segue"]) {
    
        // The background user feedback view controller.
        self.bgFeedBackVC = segue.destinationViewController;
        
    } else if ([segue.identifier isEqualToString:@"onboarding segue"]) {
        
        // The onboarding view controller.
        if (self.shouldPresentOnBoarding) {
            self.onBoardingVC = segue.destinationViewController;
            self.onBoardingVC.delegate = self;
        }
        
    } else if ([segue.identifier isEqualToString:@"controls segue"]) {
        
        // User controls (record button, confirmation buttons, user messages)
        self.controlsVC = segue.destinationViewController;
        self.controlsVC.delegate = self;
    }
}

#pragma mark - Capture session
-(void)initCaptureSession
{
    // Initialize the video processor.
    // Set the recorderVC as the session delegate.
    self.captureSession = [[HMCaptureSession alloc] init];
    self.captureSession.prefferedSessionPreset = AVCaptureSessionPreset640x480;
    self.captureSession.prefferedSize = CGSizeMake(480, 480);
    self.captureSession.sessionDelegate = self;
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateIdle info:nil];

    // Setup and start the capture session.
    [self.captureSession setupAndStartCaptureSession];
    
    // The preview view
    self.captureSession.sessionDisplayDelegate = self.previewVC;
    
    // Initialized.
    HMLOG(TAG, DBG, @"Initialized capture session");
}

#pragma mark - Video processing
-(void)initVideoProcessing
{
    //
    // Start green machine processing.
    // And check for errors in initalization.
    //
    NSError *error;
    HMGreenMachine *gm = [HMGreenMachine greenMachineWithBGImageFileName:@"test480x480"
                                                         contourFileName:@"headAndChest480X480"
                                                                   error:&error];
    if (error) {
        HMLOG(TAG, ERR, @"GM error: %@", [error localizedDescription]);
        [self.captureSession stopAndTearDownCaptureSession];
        return;
    }

    // Give the initialized instance of the green machine
    // to the control of the capture session object.
    // The capture session will use the green machine for
    // processing the feed of video frames.
    [self.captureSession initializeVideoProcessor:gm];
    HMLOG(TAG, DBG, @"Initialized video processing.");
}

#pragma mark - BG Feedback
-(void)hideBGFeedBackAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideBGFeedBackAnimated:NO];
        }];
        return;
    }

    self.guiBGFeedBackContainer.alpha = 0;
    self.guiBGFeedBackContainer.transform = CGAffineTransformMakeScale(1.6, 1.6);
}

-(void)showBGFeedBackAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self showBGFeedBackAnimated:NO];
        }];
        return;
    }
    
    self.guiBGFeedBackContainer.alpha = 1;
    self.guiBGFeedBackContainer.transform = CGAffineTransformIdentity;
}

#pragma mark - The record button
-(void)hideRecordButtonAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideRecordButtonAnimated:NO];
        }];
        return;
    }
    
    self.guiRecordButton.alpha = 0;
}

-(void)showRecordButtonAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self showRecordButtonAnimated:NO];
        }];
        return;
    }
    
    self.guiRecordButton.alpha = 1;
}

#pragma mark - Capture session delegate
-(void)recordingWillStart
{
    
}

-(void)recordingDidStart
{
    
}

-(void)recordingWillStop
{
    
}

-(void)recordingDidStop
{
    
}

#pragma mark - Onboarding delegate
-(void)onboardingDidGoBackToStageNumber:(NSInteger)stageNumber
{
    EMOnBoardingStage stage = (EMOnBoardingStage)stageNumber;
    switch (stage) {
        case EMOnBoardingStageWelcome:
            [self handleStateWithInfo:nil nextState:@(EMRecorderStateStarting)];
            break;
            
        default:
            break;
    }
}

#pragma mark - Updating States
-(void)initState
{
    self.recorderState = EMRecorderStateStarting;
}

-(void)handleState
{
    [self handleStateWithInfo:nil nextState:nil];
}

-(void)handleStateWithInfo:(NSDictionary *)info
{
    [self handleStateWithInfo:info nextState:nil];
}

-(void)handleStateWithInfo:(NSDictionary *)info nextState:(NSNumber *)nextState
{
    if (nextState) {
        self.recorderState = (EMRecorderState)[nextState integerValue];
    }
    
    switch (self.recorderState) {
        case EMRecorderStateStarting:
            // Just started. Reset UI and after a short while
            // change to the bg Detection should start state.
            [self stateJustStarted];
            break;
            
        case EMRecorderStateBGDetectionShouldStart:
            // Ready to start background detection.
            [self stateStartBGDetection];
            break;
            
        case EMRecorderStateBGDetectionInProgress:
            // If good background threshold satisfied, will prepare for FG extraction.
            [self stateBGDetectionInProgress:info];
            break;
            
        case EMRecorderStateFGExtractionShouldStart:
            // Ready to start FG extraction.
            [self stateStartFGExtraction];
            break;
            
        case EMRecorderStateFGExtractionInProgress:
            // Do nothing in this state.
            // It is upto the user to start the countdown to recording,
            // by pressing the record button.
            break;
            
        case EMRecorderStateRecordingCountDown:
            // If counted down to zero, will need to start recording.
            // If user canceled the countdown, will do nothing
            // and go back to the EMRecorderStateFGExtractionInProgress state.
            [self stateCountDownToRecording];
            break;
            
        case EMRecorderStateRecording:
            // TODO: implement.
            break;
            
        case EMRecorderStateDone:
            // TODO: implement.
            break;
            
    }
}

#pragma mark - State methods
/* 
 For all state handling methods, stick (as much as possible) to this format:
 
    //
    // Capture session and video processing.
    //
    .
    .
    .
 
    //
    // Recorder and UI state.
    //
    .
    .
    .
 
    //
    // Onboarding UI
    //
    .
    .
    .
    
 */

-(void)stateJustStarted
{
    //
    // Capture session and video processing.
    //
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateIdle
                                            info:nil];
    
    //
    // Recorder and UI state.
    //
    [self.controlsVC setState:EMRecorderControlsStateHidden
                     animated:YES];
    [self showBGFeedBackAnimated:YES];
    
    // Wait a bit before going to the next state.
    dispatch_after(DTIME(1.5), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1 animations:^{
            self.guiPreviewCover.alpha = 0;
        }];

        // Change to the BG Detection should start state.
        [self handleStateWithInfo:nil nextState:@(EMRecorderStateBGDetectionShouldStart)];
    });

    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageWelcome
                                     animated:NO];
}

-(void)stateStartBGDetection
{
    //
    // Capture session and video processing.
    //

    // Don't process frames, but once in awhile check a frame
    // and give it a good/bad background mark.
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateInspectFrames
                                            info:nil];
    
    //
    // Recorder and UI state.
    //
    self.recorderState = EMRecorderStateBGDetectionInProgress;
    [self.controlsVC setState:EMRecorderControlsStateBackgroundDetection
                     animated:YES];
    
    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageAlign
                                     animated:YES];
}

-(void)stateBGDetectionInProgress:(NSDictionary *)info
{
    //
    // Recorder and UI state.
    //
    
    // do nothing if still didn't get a satisfactory indication
    // about good background.
    if (info[hmkInfoGoodBGSatisfied] == nil)
        return;
    
    // Info provided indicates that a good background threshold was satisfied.
    // It is time to stop the background detection sampling and start
    // the foreground extraction algorithm.
    [self handleStateWithInfo:nil
                    nextState:@(EMRecorderStateFGExtractionShouldStart)];
}


-(void)stateStartFGExtraction
{
    //
    // Capture session and video processing.
    //
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateProcessFrames
                                            info:nil];

    //
    // Recorder and UI state.
    //

    // No need for the UI that shows BG Detection feedback.
    [self hideBGFeedBackAnimated:YES];
    
    // Show the record button.
    [self.controlsVC setState:EMRecorderControlsStateReadyToRecord
                     animated:YES];
    
    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageExtractionPreview
                                     animated:YES];

}

-(void)stateCountDownToRecording
{
}


#pragma mark - EMRecorderControlsDelegate
-(void)controlSentAction:(EMRecorderControlsAction)action info:(NSDictionary *)info
{
    if (action == EMRecorderControlsActionContinueWithBadBackground &&
        self.recorderState == EMRecorderStateBGDetectionInProgress) {
        [self handleStateWithInfo:nil nextState:@(EMRecorderStateFGExtractionShouldStart)];
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDebugButton:(id)sender
{
}


@end
