//
//  PreviewViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "PreviewViewController.h"
#import "HMPreviewView.h"
#import "HMCaptureSession.h"

@interface PreviewViewController () <
    HMCaptureSessionDelegate
>

@property (strong, nonatomic) IBOutlet HMPreviewView *guiGLPreviewView;
@property (strong, nonatomic) HMCaptureSession *videoProcessor;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initPreview];
}

#pragma mark - GL Preview
-(void)initPreview
{
    // Initialize the video processor.
    self.videoProcessor = [[HMCaptureSession alloc] init];
    self.videoProcessor.delegate = self;
    
    // Setup and start the capture session.
    [self.videoProcessor setupAndStartCaptureSession];
}

#pragma mark - HMCaptureSessionDelegate
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
    // Don't make OpenGLES calls while in the background.
    if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
        [self.guiGLPreviewView displayPixelBuffer:pixelBuffer];
    
}

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

@end
