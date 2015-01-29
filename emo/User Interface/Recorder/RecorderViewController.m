//
//  ViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

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
    [self initCaptureSession];
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
    self.captureSession = [[HMCaptureSession alloc] init];
    self.captureSession.sessionDelegate = self;

    // Setup and start the capture session.
    [self.captureSession setupAndStartCaptureSession];
    
    // The preview view
    self.captureSession.sessionDisplayDelegate = self.previewVC;
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
    // Start green machine processing.
    //[self.captureSession startImageProcessing];
}


@end
