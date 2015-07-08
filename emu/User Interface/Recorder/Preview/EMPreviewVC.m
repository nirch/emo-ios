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
@property (weak, nonatomic) IBOutlet UIImageView *guiFakeFootage;

@property (nonatomic) UIImageView *focusPointView;

@end

@implementation EMPreviewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    #if (TARGET_IPHONE_SIMULATOR)
        self.guiFakeFootage.hidden = NO;
    #endif
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.guiGLPreviewView initializeGL];
}

-(void)fakeExtraction
{
    self.guiFakeFootage.image = [UIImage imageNamed:@"fakeExtraction"];
}

#pragma mark - HMCaptureSessionDelegate
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
    // Don't make OpenGLES calls while in the background.
    if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
        [self.guiGLPreviewView displayPixelBuffer:pixelBuffer];
}

-(UIImageView *)focusPointView
{
    if (_focusPointView == nil) {
        _focusPointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _focusPointView.image = [UIImage imageNamed:@"focusPoint"];
        [self.view addSubview:_focusPointView];
    }
    return _focusPointView;
}

-(void)showFocusViewOnPoint:(CGPoint)point
{
    // Position
    CGFloat x = MIN(MAX(point.x,0.0f),1.0f);
    CGFloat y = MIN(MAX(point.y,0.0f),1.0f);
    x = x * self.view.bounds.size.width;
    y = y * self.view.bounds.size.height;
    
    __weak UIImageView *v = self.focusPointView;
    v.center = CGPointMake(x, y);
    v.hidden = NO;
    v.transform = CGAffineTransformMakeScale(2.4, 2.4);
    
    // Animate
    [UIView animateWithDuration:2.5 animations:^{
        //v.alpha = 0.4;
        v.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //v.alpha = 1.0;
        [UIView animateWithDuration:0.3
                              delay:1.5
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                         } completion:^(BOOL finished) {
                             v.hidden = YES;
                         }];
    }];
}

@end
