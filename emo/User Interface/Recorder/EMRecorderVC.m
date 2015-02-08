//
//  ViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"RecorderVC"

#import "HMSDK.h"

#import "EMRecorderVC.h"
#import "EMRecorderVC+States.h"

#import "EMPreviewVC.h"
#import "EMBGFeedBackVC.h"

@interface EMRecorderVC () <
    HMCaptureSessionDelegate
>

@property (weak, nonatomic) IBOutlet UIView *guiUserControls1Container;
@property (weak, nonatomic) IBOutlet UIView *guiUserControls2Container;

// The video capture session
@property (strong, nonatomic, readwrite) HMCaptureSession *captureSession;

// The preview VC
@property (weak, nonatomic) EMPreviewVC *previewVC;
@property (weak, nonatomic) EMBGFeedBackVC *bgFeedBackVC;

@end

@implementation EMRecorderVC

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
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUI];

    // Observers
    [self initObservers];
    
    // Start the flow of the recorder.
    [self handleStateWithInfo:nil];
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
    self.captureSession.shouldInspectVideoFrames = NO;
    self.captureSession.shouldProcessVideoFrames = NO;

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

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDebugButton:(id)sender
{
}


@end
