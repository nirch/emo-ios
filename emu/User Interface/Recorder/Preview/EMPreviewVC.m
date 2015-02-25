//
//  PreviewViewController.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPreviewVC.h"
#import "HMPreviewView.h"
#import "HMCaptureSession.h"

@interface EMPreviewVC ()

@property (strong, nonatomic) IBOutlet HMPreviewView *guiGLPreviewView;

@end

@implementation EMPreviewVC

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
