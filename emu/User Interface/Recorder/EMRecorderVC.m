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

#import "EMDB.h"

#import "EMUISound.h"
#import "EMRecorderVC.h"
#import "EMPreviewVC.h"
#import "EMBGFeedBackVC.h"
#import "EMOnboardingVC.h"
#import "EMControlsBarVC.h"
#import "EMRecordButton.h"
#import "EMBackend.h"
#import "EMPNGSequenceWriter.h"
#import "EMRenderManager.h"
#import "EMunizingView.h"
#import "EMLabel.h"
#import "EMAnimatedGifPlayer.h"
#import "EMMainVC.h"

@interface EMRecorderVC () <
    HMCaptureSessionDelegate,
    EMOnboardingDelegate,
    EMRecorderControlsDelegate
>


@property (nonatomic) Package *package;
@property (nonatomic) Emuticon *emuticonToUpdate;

@property (nonatomic) Emuticon *previewEmuticon;

//
// Containers and sub view controllers
//

// User controls: recorder flow, user interaction, record, etc.
@property (weak, nonatomic) IBOutlet UIView *guiUserControlsContainer;
@property (weak) EMControlsBarVC *controlsVC;


// Background detection
@property (weak, nonatomic) IBOutlet UIView *guiBGFeedBackContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiGoodBGIcon;
@property (weak, nonatomic) IBOutlet UIImageView *guiBadBGIcon;
@property (weak, nonatomic) EMBGFeedBackVC *feedBackVC;


// The preview container and view controller
@property (weak, nonatomic) IBOutlet UIView *guiPreviewContainerView;
@property (weak, nonatomic) EMPreviewVC *previewVC;


// Onboarding
@property (nonatomic, readwrite) BOOL shouldPresentOnBoarding;
@property (weak) EMOnboardingVC *onBoardingVC;


// Result review view controller
@property (weak, nonatomic) IBOutlet UIView *guiResultContainer;
@property (weak, nonatomic) EMAnimatedGifPlayer *gifPlayerVC;


// Please wait, noodnik!
@property (weak, nonatomic) IBOutlet EMunizingView *guiPleaseWaitView;
@property (weak, nonatomic) IBOutlet EMLabel *guiPleaseWaitLabel;


//
// The video capture session
//
@property (strong, nonatomic, readwrite) HMCaptureSession *captureSession;


//
// Recording and recorder states
//
@property (readwrite) EMRecorderState recorderState;

// Layout
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintCameraPreviewTrailing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintCameraPreviewLeading;


@end

@implementation EMRecorderVC

@synthesize recorderState = _recorderState;

+(EMRecorderVC *)recorderVCForFlow:(EMRecorderFlowType)flowType
                              info:(NSDictionary *)info
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"EMRecorder" bundle:nil];
    EMRecorderVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"recorder vc"];
    vc.flowType = flowType;
    vc.emuticonToUpdate = info[emkEmuticon];

    if (vc.emuticonToUpdate) {
        vc.package = vc.emuticonToUpdate.emuDef.package;
    } else {
        vc.package = info[emkPackage];
    }
    vc.info = info;
    return vc;
}


-(id)awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    self = [super awakeAfterUsingCoder:aDecoder];
    if (self) {
        // Implement initialization with onboarding disabled.
        self.shouldPresentOnBoarding = YES;
    }
    return self;
}



#pragma mark - VC life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    HMLOG(TAG, EM_DBG, @"Recorder did load");
    
    // Initializations
    [self initData];
    [self initState];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    HMLOG(TAG, EM_DBG, @"Recorder will appear");
    
    [self initGUI];
    [self.view setNeedsDisplay];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HMLOG(TAG, EM_DBG, @"Recorder did appear");
    
    // Observers
    [self initObservers];
    
    // Start the flow of the recorder.
    [self handleState];

    // Start the capture session and video processing
    [self initCaptureSession];
    [self initVideoProcessing];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    HMLOG(TAG, EM_DBG, @"Recorder will disappear");

    [self removeObservers];
    [self tearDownCaptureSession];
}

-(void)dealloc
{
    HMLOG(TAG, EM_DBG, @"Recorder dealloc");
}

#pragma mark - Memory warnings
-(void)didReceiveMemoryWarning
{
    // Some info
    NSDictionary *info = @{
                           rkDescription:@"memory warning",
                           rkWhere:@"EMMainVC"
                           };
    
    // Log remotely
    HMLOG(TAG, EM_ERR, @"Memory warning in recorder");
    REMOTE_LOG(@"EMMainVC Memory warning");
    
    // Analytics
    [HMReporter.sh analyticsEvent:akLowMemoryWarning info:info];
    
    // Go boom on a test application.
    [HMReporter.sh explodeOnTestApplicationsWithInfo:info];
}


#pragma mark - Initializations
-(void)initData
{
    self.recordingDuration = self.package? [self.package defaultCaptureDuration]: 2.0;
}

-(void)initGUI
{
    // Start hidden
    self.guiPreviewContainerView.alpha = 0;
    self.guiBGFeedBackContainer.alpha = 0;
    
    // Camera preview border
    CALayer *layer = self.guiPreviewContainerView.layer;
    layer.cornerRadius = 10;
    layer.borderWidth = 7;
    layer.borderColor = [UIColor whiteColor].CGColor;
    
    // BG feedback
    layer = self.guiBGFeedBackContainer.layer;
    layer.cornerRadius = 10;
    layer.borderWidth = 7;
    layer.borderColor = [UIColor whiteColor].CGColor;
    [self hideBGIconsAnimated:NO];
    
    // The "please wait" view
    [self.guiPleaseWaitView setup];
    self.guiPleaseWaitLabel.hidden = YES;
    
    // Only iPhone4s needs special treatment of the layout
    [self layoutFixesIfRequired];
    
    //
    // Style kit related
    //
    [self initStyle];
}

-(void)layoutFixesIfRequired
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight > 480.0) return;
    
    // Fu@#$%ing iPhone 4s needs special treatment of the layout.
    self.constraintCameraPreviewLeading.constant = 15;
    self.constraintCameraPreviewTrailing.constant = -15;
}

-(void)initStyle
{
    
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On background detection information received.
    [nc addUniqueObserver:self
                 selector:@selector(onBackgroundDetectionInfo:)
                     name:hmkNotificationBGDetectionInfo
                   object:nil];
    
    // On rendering preview finshed.
    [nc addUniqueObserver:self
                 selector:@selector(onPreviewRenderingFinished:)
                     name:hmkRenderingFinishedPreview
                   object:nil];
    
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkNotificationBGDetectionInfo];
    [nc removeObserver:hmkRenderingFinishedPreview];
}

#pragma mark - Observers handlers
-(void)onBackgroundDetectionInfo:(NSNotification *)notification
{
    // This info is interesting only when the recorder
    // is in the background detection state.
    // Otherwise, ignore the info.
    if (self.recorderState != EMRecorderStateBGDetectionInProgress)
        return;
    
    NSDictionary *info = notification.userInfo;
    CGFloat weight = [info[hmkInfoBGMarkWeight] floatValue];

    // Update indicator about the good/bad background weight.
    self.feedBackVC.goodBackgroundWeight = weight;

    // Pass info to the user controls that will show messages
    // about good/bad backgrounds.
    [self.controlsVC updateBackgroundInfo:info];
    
    
    // Show/Hide the good/bad bg icon.
    if (weight > 0.8 && self.guiGoodBGIcon.alpha <= 0) {
        [self hideBGIconsAnimated:YES];
    } else if (weight < 0.8 && self.guiBadBGIcon.alpha <= 0) {
        [self showBadBGIconAnimated:YES];
    }

    // Check if good bg threshold was satisfied.
    if (info[hmkInfoGoodBGSatisfied]) {
        // Good background threshold was satisfied!
        [self handleStateWithInfo:@{hmkInfoGoodBGSatisfied:@YES}];
    }
}

-(void)onPreviewRenderingFinished:(NSNotification *)notification
{
    // Get the newly createed preview emuticon
    NSDictionary *info = notification.userInfo;
    NSString *emuOID = info[emkEmuticonOID];

    Emuticon *emu = [Emuticon findWithID:emuOID
                                 context:EMDB.sh.context];
    
    if (emu == nil) {
        // Epic fail :-(
        [self epicFail];
        return;
    }
    
    [self handleStateWithInfo:info
                    nextState:@(EMRecorderStateReviewPreview)];
}

#pragma mark - Good/Bad BG Icon
-(void)showGoodBGIconAnimated:(BOOL)animated
{
    [self hideBGIconsAnimated:NO];

    if (!animated) {
        self.guiGoodBGIcon.transform = CGAffineTransformIdentity;
        self.guiGoodBGIcon.alpha = 1;
        return;
    }
    
    [UIView animateWithDuration:0.5
                          delay:0.3
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.guiGoodBGIcon.transform = CGAffineTransformIdentity;
                         self.guiGoodBGIcon.alpha = 1;
                     } completion:nil];
}

-(void)showBadBGIconAnimated:(BOOL)animated
{
    [self hideBGIconsAnimated:NO];
    
    if (!animated) {
        self.guiBadBGIcon.transform = CGAffineTransformIdentity;
        self.guiBadBGIcon.alpha = 1;
        return;
    }
    
    [UIView animateWithDuration:0.5
                          delay:0.3
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.guiBadBGIcon.transform = CGAffineTransformIdentity;
                         self.guiBadBGIcon.alpha = 1;
                     } completion:nil];
}

-(void)hideBGIconsAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideBGIconsAnimated:NO];
        }];
        return;
    }

    self.guiGoodBGIcon.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.guiGoodBGIcon.alpha = 0;
    self.guiBadBGIcon.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.guiBadBGIcon.alpha = 0;
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
        
        // The camera preview view controller.
        self.previewVC = segue.destinationViewController;

    } else if ([segue.identifier isEqualToString:@"embed bg feedback segue"]) {
    
        // The background user feedback view controller.
        self.feedBackVC = segue.destinationViewController;
        self.feedBackVC.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"onboarding segue"]) {
        
        // The onboarding view controller.
        if (self.shouldPresentOnBoarding) {
            self.onBoardingVC = segue.destinationViewController;
            self.onBoardingVC.flowType = self.flowType;
            self.onBoardingVC.delegate = self;
        }
        
    } else if ([segue.identifier isEqualToString:@"controls segue"]) {
        
        // User controls (record button, confirmation buttons, user messages)
        self.controlsVC = segue.destinationViewController;
        self.controlsVC.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"review result segue"]) {
        
        // Presenting and playing the result of the render.
        self.gifPlayerVC = segue.destinationViewController;
        
    }
}

#pragma mark - Epic Fail
-(void)epicFail
{
    // Something went terribly wrong.
    // Will restart the flow after showing an alert to the user.
    UIAlertController *alertVC = [UIAlertController new];
    [alertVC addAction:[UIAlertAction actionWithTitle:LS(@"TRY_AGAIN")
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  [self stateRestart];
                                              }]];
    alertVC.title = LS(@"EPIC_FAIL");
    alertVC.message = LS(@"SOMETHING_WENT_WRONG");
    [self presentViewController:alertVC animated:YES completion:nil];
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
    HMLOG(TAG, EM_DBG, @"Initialized capture session");
}

-(void)tearDownCaptureSession
{
    [self.captureSession stopAndTearDownCaptureSession];
    self.captureSession = nil;
}

#pragma mark - Video processing
-(void)initVideoProcessing
{
    //
    // Start green machine processing.
    // And check for errors in initalization.
    //
    NSError *error;
    HMGreenMachine *gm = [HMGreenMachine greenMachineWithBGImageFileName:@"clear480x480"
                                                         contourFileName:@"1" // @"headAndChest480X480"
                                                                   error:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"GM error: %@", [error localizedDescription]);
        [self.captureSession stopAndTearDownCaptureSession];
        return;
    }

    // Give the initialized instance of the green machine
    // to the control of the capture session object.
    // The capture session will use the green machine for
    // processing the feed of video frames.
    [self.captureSession initializeVideoProcessor:gm];
    HMLOG(TAG, EM_DBG, @"Initialized video processing.");
}


#pragma mark - Output
-(NSURL *)outputFolder
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Capture session delegate
-(void)recordingDidStartWithInfo:(NSDictionary *)info
{
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
    
    HMLOG(TAG, DEBUG, @"recording did start with info %@", info);
}


-(void)recordingDidStopWithInfo:(NSDictionary *)info
{
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
    HMLOG(TAG, DEBUG, @"recording did stop with info %@", info);

    // Create a new user footage object.
    UserFootage *footage = [UserFootage userFootageWithInfo:info context:EMDB.sh.context];
    [EMDB.sh save];
    
    // Get an emuticon definition to be used for the preview.
    EmuticonDef *emuDefForPreview;
    if (self.emuticonToUpdate) {
        emuDefForPreview = self.emuticonToUpdate.emuDef;
    } else {
        emuDefForPreview = [self.package findEmuDefForPreviewInContext:EMDB.sh.context];
    }
    
    // Send the footage to preview rendering.
    [EMRenderManager.sh renderPreviewForFootage:footage
                                     withEmuDef:emuDefForPreview];
}


-(void)recordingWasCanceledWithInfo:(NSDictionary *)info
{
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");

    HMLOG(TAG, DEBUG, @"recording was canceled with info %@", info);
}


-(void)recordingDidFailWithError:(NSError *)error
{
    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");

    HMLOG(TAG, DEBUG, @"recording did fail with error %@", error);
    [self epicFail];
}

#pragma mark - Onboarding delegate
-(void)onboardingDidGoBackToStageNumber:(NSInteger)stageNumber
{
    EMOnBoardingStage stage = (EMOnBoardingStage)stageNumber;
    switch (stage) {
            
        case EMOnBoardingStageWelcome:
            [self stateRestart];
            break;
            
        default:
            break;
    }
}

-(void)onboardingUserWantsToCancel
{
    if (self.previewEmuticon)
        [self.previewEmuticon deleteAndCleanUp];
    
    // Just dismiss the recorder, doing nothing.
    [self.delegate recorderCanceledByTheUserInFlow:self.flowType
                                              info:self.info];
}

#pragma mark - Updating States
-(void)stateRestart
{
    // Restart the flow.
    [self handleStateWithInfo:nil
                    nextState:@(EMRecorderStateStarting)];
}

-(void)setRecorderState:(EMRecorderState)recorderState
{
    @synchronized(self) {
        _recorderState = recorderState;
    }
}

-(EMRecorderState)recorderState
{
    @synchronized(self) {
        return _recorderState;
    }
}

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

-(void)handleStateWithInfo:(NSDictionary *)info
                 nextState:(NSNumber *)nextState
{
    if (nextState) {
        self.recorderState = (EMRecorderState)[nextState integerValue];
    }
    
    switch (self.recorderState) {
        case EMRecorderStateStarting:
            // Just started. Reset UI and after a short while
            // change to the bg Detection should start state.
            [self _stateJustStarted];
            break;
            
        case EMRecorderStateBGDetectionShouldStart:
            // Ready to start background detection.
            [self _stateStartBGDetection];
            break;
            
        case EMRecorderStateBGDetectionInProgress:
            // If good background threshold satisfied, will prepare for FG extraction.
            [self _stateBGDetectionInProgress:info];
            break;
            
        case EMRecorderStateFGExtractionShouldStart:
            // Ready to start FG extraction.
            [self _stateShouldStartFGExtraction:info];
            break;
            
        case EMRecorderStateFGExtractionInProgress:
            // Do nothing in this state.
            // It is upto the user to start the countdown to recording,
            // by pressing the record button.
            break;
            
        case EMRecorderStateShouldStartRecording:
            // Should start recording video.
            // Initiate the start of the recording on the output queue.
            [self _stateShouldStartRecording];
            break;
            
        case EMRecorderStateRecording:
            // No need to do anything in this state.
            // Everything is handled in the background.
            break;
            
        case EMRecorderStateFinishingUp:
            // The recording session has ended for the user.
            // The actual session continues in the background, so we
            // will show some kind of "please wait" indication in the UI
            // until the background session reports that it finished.
            [self _stateUserShouldWaitWhileFinishingUp];
            break;
        
        case EMRecorderStateReviewPreview:
            [self _stateReviewPreviewWithInfo:info];
            break;
        
        case EMRecorderStateDone:
            [self _stateDone];
            break;
            
        case EMRecorderStateFatalError:
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

-(void)_stateJustStarted
{
    //
    // Capture session and video processing.
    //
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateIdle
                                            info:nil];
    
    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];
    [self.controlsVC setState:EMRecorderControlsStateHidden
                     animated:YES];
    
    self.feedBackVC.goodBackgroundWeight = 0;
    [self.feedBackVC showBGFeedbackAnimated:NO];
    [self.feedBackVC hideRecordingProgressAnimated:NO];
    
    [self showCameraFeedUIAnimated:YES];
    self.guiPleaseWaitLabel.hidden = YES;
    [self hideResultUIAnimated:YES];
    
    // Wait a bit before going to the next state.
    dispatch_after(DTIME(0.7), dispatch_get_main_queue(), ^{
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

-(void)_stateStartBGDetection
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
    [self hidePleaseWait];
    self.recorderState = EMRecorderStateBGDetectionInProgress;
    [self.controlsVC setState:EMRecorderControlsStateBackgroundDetection
                     animated:YES];
    [self hideBGIconsAnimated:NO];

    
    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageAlign
                                     animated:YES];
}

-(void)_stateBGDetectionInProgress:(NSDictionary *)info
{
    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];

    // do nothing if still didn't get a satisfactory indication
    // about good background.
    if (info[hmkInfoGoodBGSatisfied] == nil)
        return;
    
    // Info provided indicates that a good background threshold was satisfied.
    // It is time to stop the background detection sampling and start
    // the foreground extraction algorithm.
    [self handleStateWithInfo:info
                    nextState:@(EMRecorderStateFGExtractionShouldStart)];
}

-(void)_stateShouldStartFGExtraction:(NSDictionary *)info
{
    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];

    // Was the threshold of good background reached?
    BOOL satisfactoryBGDetected = (info != nil && info[hmkInfoGoodBGSatisfied]);
    
    // Play a happy sound.
    if (satisfactoryBGDetected)
        [EMUISound.sh playSoundNamed:SND_HAPPY];
    
    // Hide the background detection user interface.
    [self.feedBackVC hideBGFeedbackAnimated:YES];
    [self.controlsVC setState:EMRecorderControlsStatePreparing
                     animated:NO
                         info:info];
    
    // Show good background indications
    if (satisfactoryBGDetected) {
        [self showGoodBGIconAnimated:YES];
    } else {
        [self hideBGIconsAnimated:YES];
    }
    
    // Wait a bit and start extraction.
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        [self _stateStartFGExtraction];
    });
}

-(void)_stateStartFGExtraction
{
    //
    // Capture session and video processing.
    //
    [self.captureSession setVideoProcessingState:HMVideoProcessingStateProcessFrames
                                            info:nil];

    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];

    // No need for the UI that shows BG Detection feedback.
    [self setRecorderState:EMRecorderStateFGExtractionInProgress];
    [self hideBGIconsAnimated:NO];

    
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



-(void)_stateShouldStartRecording
{
    //
    // Capture session and video processing.
    //
    
    // Create a new writer to be used in recording the png sequence.
    EMPNGSequenceWriter *writer = [EMPNGSequenceWriter new];
    writer.writesFramesOfType = HMWritesFramesOfTypeImageType;
    [self.captureSession startRecordingUsingWriter:writer
                                          duration:self.recordingDuration];
    
    
    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];

    // Show recording progress
    [self.feedBackVC showRecordingProgressOfDuration:self.recordingDuration];
    
    // Play start recording sound
    [EMUISound.sh playSoundNamed:SND_START_RECORDING];
    
    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageRecording
                                     animated:YES];

    // Recording!
    [self handleStateWithInfo:nil
                    nextState:@(EMRecorderStateRecording)];
}

-(void)_stateUserShouldWaitWhileFinishingUp
{
    //
    // Recorder and UI state.
    //
    [EMUISound.sh playSoundNamed:SND_RECORDING_ENDED];
    [self showPleaseWait];
    
    // Well, we can fade out recording UI
    // This doesn't stop the recording
    // (the capture session is handling that, not the view controller.
    // the view controller will be notified when the background processes
    // are finished)
    [self.feedBackVC hideRecordingProgressAnimated:NO];
    [self hideCameraFeedUIAnimated:YES];
    [self.guiPleaseWaitView startAnimating];
    
    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageFinishingUp
                                     animated:YES];    
}


-(void)_stateReviewPreviewWithInfo:(NSDictionary *)info
{
    //
    // Recorder and UI state.
    //
    [self hidePleaseWait];
    
    NSString *emuOID = info[emkEmuticonOID];
    
    self.previewEmuticon = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    self.gifPlayerVC.animatedGifURL = [self.previewEmuticon animatedGifURL];
    
    //self.gifPlayerVC.animatedGifURL
    [self showResultUIAnimated:YES];
    [self.controlsVC setState:EMRecorderControlsStateReview animated:YES];
    

    //
    // Onboarding UI
    //
    if (self.shouldPresentOnBoarding)
        [self.onBoardingVC setOnBoardingStage:EMOnBoardingStageReview
                                     animated:YES];
}


-(void)_stateDone
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];

    if (self.flowType == EMRecorderFlowTypeOnboarding) {
        
        //
        // Finished with onboarding!
        //
        
        // Don't enter onboarding again.
        appCFG.onboardingPassed = @YES;
        
        // Make the new footage, the master footage app wide.
        UserFootage *newFootage = [self.previewEmuticon previewUserFootage];
        if (newFootage) {
            appCFG.prefferedFootageOID = newFootage.oid;
        }
        
        // Delete the rendered preview emuticon
        [self.previewEmuticon deleteAndCleanUp];
        
        // Create and render all required emuticon objects in first package.
        // TODO: support and test with multiple packages.
        [self.package createMissingEmuticonObjects];

    } else if (self.flowType == EMRecorderFlowTypeRetakeAll) {

        // Make the new footage, the master footage app wide
        // and delete the old master footage.
        UserFootage *newFootage = [self.previewEmuticon previewUserFootage];
        UserFootage *oldFootage = [UserFootage masterFootage];
        [oldFootage deleteAndCleanUp];
        appCFG.prefferedFootageOID = newFootage.oid;
        
        // Clean up all emuticons that don't have their own specific footage.
        // TODO: support and test with multiple packages.
        [self.package createMissingEmuticonObjects];
        [self.package cleanUpEmuticonsWithNoSpecificFootage];
        
    } else if (self.flowType == EMRecorderFlowTypeRetakeForPackage) {
        
        // TODO: finish implementation.
        
    } else if (self.flowType == EMRecorderFlowTypeRetakeForSpecificEmuticons) {
        
        // Cleanup the specific emuticon related to this flow.
        Emuticon *emu = self.emuticonToUpdate;
        [emu cleanUp];
        
        // Set the new footage as the emuticon preffered footage.
        emu.prefferedFootageOID = self.previewEmuticon.prefferedFootageOID;
        
        
    }
    
    // Delete the preview emuticon.
    [self.previewEmuticon deleteAndCleanUp];
    [EMDB.sh save];
    
    // Tell delegate to dismiss the recorder.
    [self.delegate recorderWantsToBeDismissedAfterFlow:self.flowType
                                                  info:self.info];
}

#pragma mark - Result Show/Hide
-(void)hideResultUIAnimated:(BOOL)animated
{
    
    
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self hideResultUIAnimated:NO];
                         } completion:nil];
        return;
    }
    
    CGAffineTransform t = CGAffineTransformMakeTranslation(30, 0);
    self.guiResultContainer.transform = t;
    self.guiResultContainer.alpha = 0;
    [self.gifPlayerVC stopAnimating];
}

-(void)showResultUIAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self showResultUIAnimated:NO];
                         } completion:nil];
        return;
    }
    
    self.guiResultContainer.alpha = 1;
    self.guiResultContainer.transform = CGAffineTransformIdentity;
}

#pragma mark - Camera Feed UI Show/Hide
-(void)hideCameraFeedUIAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self hideCameraFeedUIAnimated:NO];
                         } completion:nil];
        return;
    }

    CGAffineTransform t = CGAffineTransformMakeTranslation(-30, 0);
    self.guiBGFeedBackContainer.transform = t;
    self.guiBGFeedBackContainer.alpha = 0;
    self.guiPreviewContainerView.alpha = 0;
    self.guiPreviewContainerView.transform = t;
}

-(void)showCameraFeedUIAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self showCameraFeedUIAnimated:NO];
                         } completion:nil];
        return;
    }
    
    self.guiBGFeedBackContainer.alpha = 1;
    self.guiBGFeedBackContainer.transform = CGAffineTransformIdentity;

    self.guiPreviewContainerView.alpha = 1;
    self.guiPreviewContainerView.transform = CGAffineTransformIdentity;
    
    [self.guiPleaseWaitView stopAnimating];
}

#pragma mark - Show/Hide please wait
-(void)showPleaseWait
{
    self.guiPleaseWaitLabel.hidden = NO;
    self.guiPleaseWaitLabel.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiPleaseWaitLabel.alpha = 1;
    }];
    
    [self.guiPleaseWaitView startAnimating];
}

-(void)hidePleaseWait
{
    self.guiPleaseWaitLabel.hidden = YES;
    [self.guiPleaseWaitView stopAnimating];
}

#pragma mark - EMRecorderControlsDelegate
-(void)controlSentAction:(EMRecorderControlsAction)action info:(NSDictionary *)info
{
    if (action == EMRecorderControlsActionContinueWithBadBackground &&
        self.recorderState == EMRecorderStateBGDetectionInProgress) {

        //
        // User pressed to continue with bad background while bg detection is in progress
        // Should start FG extraction anyway.
        //
        [self handleStateWithInfo:nil
                        nextState:@(EMRecorderStateFGExtractionShouldStart)];
        
    } else if (action == EMRecorderControlsActionStartRecording &&
               self.recorderState == EMRecorderStateFGExtractionInProgress) {
        
        //
        // User pressed record button and the record button
        // counted down to 0 without interuptions.
        //
        [self handleStateWithInfo:nil
                        nextState:@(EMRecorderStateShouldStartRecording)];
        
        
        
    } else if (action == EMRecorderControlsActionRecordingDurationEnded &&
               self.recorderState == EMRecorderStateRecording) {

        //
        // The user interface needs to show the user that the recording
        // session ended. In that state, the UI will show ask the user
        // to wait, until the background capture session actually finishes
        // in the background. This action only changes the user interface!
        // It is upto to the background capture session to actually end
        // the session and initiate the advancement to the next state.
        //
        [self handleStateWithInfo:nil
                        nextState:@(EMRecorderStateFinishingUp)];
        
    } else if (action == EMRecorderControlsActionNo &&
               self.recorderState == EMRecorderStateReviewPreview) {

        // User wasn't happy with the result.
        // Remove the footage and the rendered emuticon
        // and start over.
        [self.previewEmuticon.previewUserFootage deleteAndCleanUp];
        [self.previewEmuticon deleteAndCleanUp];
        self.previewEmuticon = nil;
        [EMDB.sh save];
        [self stateRestart];
        
    } else if (action == EMRecorderControlsActionYes &&
               self.recorderState == EMRecorderStateReviewPreview) {
        
        //
        // The user is a Happy Pappi
        // 
        //
        [self handleStateWithInfo:nil
                        nextState:@(EMRecorderStateDone)];
        
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Wrong state for action or action not implemented in %@", NSStringFromSelector(_cmd)]
                                     userInfo:nil];
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
