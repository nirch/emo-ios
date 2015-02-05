//
//  ViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"RecorderVC"

#import "HMSDK.h"
#import "RecorderViewController.h"
#import "PreviewViewController.h"

@interface RecorderViewController () <
    HMCaptureSessionDelegate
>

@property (weak, nonatomic) IBOutlet UIView *guiUserControls1Container;
@property (weak, nonatomic) IBOutlet UIView *guiUserControls2Container;

// The video capture session
@property (strong, nonatomic) HMCaptureSession *captureSession;

// The preview VC
@property (weak, nonatomic) PreviewViewController *previewVC;

@end

@implementation RecorderViewController

#pragma mark - VC life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // Initializations
    [self initCaptureSession];
    [self initVideoProcessing];

    //DDLogDebug(@"%@:Recorder view did load.", [self class]);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUI];
}

#pragma mark - Initializations
-(void)initGUI
{
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
        // The preview view.
        self.previewVC = segue.destinationViewController;
    }
}

#pragma mark - Capture session
-(void)initCaptureSession
{
    // Initialize the video processor.
    // Set the recorderVC as the session delegate.
    self.captureSession = [[HMCaptureSession alloc] init];
    self.captureSession.prefferedSessionPreset = AVCaptureSessionPreset640x480;
    self.captureSession.prefferedSize = CGSizeMake(240, 240);
    self.captureSession.sessionDelegate = self;

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
    HMGreenMachine *gm = [HMGreenMachine greenMachineWithBGImageFileName:@"test240x240"
                                                         contourFileName:@"head_and_chest_240X240"
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
