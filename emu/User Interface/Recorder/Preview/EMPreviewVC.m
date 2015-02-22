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
#import "EMProgressView.h"

@interface EMPreviewVC ()

@property (strong, nonatomic) IBOutlet HMPreviewView *guiGLPreviewView;

@property (weak, nonatomic) IBOutlet EMProgressView *guiProgressView;

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

#pragma mark - Progress View
-(void)showRecordingProgressOfDuration:(NSTimeInterval)duration
{
    [self.guiProgressView reset];
    [self.guiProgressView setValue:1
                          animated:YES
                          duration:duration];
}

@end
