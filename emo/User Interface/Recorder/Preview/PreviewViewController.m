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

@interface PreviewViewController ()

@property (strong, nonatomic) IBOutlet HMPreviewView *guiGLPreviewView;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - HMCaptureSessionDelegate
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
    // Don't make OpenGLES calls while in the background.
    if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
        [self.guiGLPreviewView displayPixelBuffer:pixelBuffer];
    
}

@end
