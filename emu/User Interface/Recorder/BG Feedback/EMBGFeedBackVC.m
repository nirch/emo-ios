//
//  EMBGFeedBackViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMBGFeedBackVC.h"
#import "EMSilhouetteView.h"
#import "AWFanOpeningView.h"
#import "EMTickingProgressView.h"
#import "EMTickingProgressDelegate.h"
#import "AppManagement.h"

@interface EMBGFeedBackVC () <
    EMTickingProgressDelegate
>

//
// Background marks feedback
//
@property (weak, nonatomic) IBOutlet UIView *guiBGFeedBackContainerView;
@property (weak, nonatomic) IBOutlet AWFanOpeningView *guiContourBadContainer;
@property (weak, nonatomic) IBOutlet AWFanOpeningView *guiContourGoodContainer;
@property (weak, nonatomic) IBOutlet EMSilhouetteView *guiSilhouetteBG;

//
// Recording progress feedback
//
@property (weak, nonatomic) IBOutlet EMTickingProgressView *guiRecordingProgressView;

// Used for debugging (should be hidden!)
@property (weak, nonatomic) IBOutlet UISlider *guiWeightSlider;

@end

@implementation EMBGFeedBackVC

@synthesize delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupEffects];
    [self update];
}

#pragma mark - initializations
-(void)initGUI
{
    self.guiWeightSlider.value = 0;
    self.guiRecordingProgressView.delegate = self;
}


-(void)setupEffects
{
    [self.guiSilhouetteBG setupEffects];
}

#pragma mark - User feedback
-(void)setGoodBackgroundWeight:(CGFloat)goodBackgroundWeight
{
    _goodBackgroundWeight = goodBackgroundWeight;
    [self update];
}

-(void)update
{
    CGFloat p1 = 1-self.goodBackgroundWeight;
    
    self.guiContourGoodContainer.startAngle = 180*p1 - 180;
    self.guiContourGoodContainer.endAngle = -180*p1 + 180;
    [self.guiContourGoodContainer updateSlice];

    self.guiContourBadContainer.startAngle = 180*p1 - 180;
    self.guiContourBadContainer.endAngle = -180*p1 + 180 - 360;
    [self.guiContourBadContainer updateSlice];
}

#pragma mark - Show/Hide BG feedback
-(void)showBGFeedbackAnimated:(BOOL)animated
{
    UIView *containerView = self.guiBGFeedBackContainerView;

    containerView.hidden = NO;

    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showBGFeedbackAnimated:NO];
        }];
        return;
    }

    containerView.alpha = 1;
    containerView.transform = CGAffineTransformIdentity;
}

-(void)hideBGFeedbackAnimated:(BOOL)animated
{
    UIView *containerView = self.guiBGFeedBackContainerView;
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self hideBGFeedbackAnimated:NO];
                         } completion:^(BOOL finished) {
                             containerView.hidden = YES;
                         }];
        return;
    }

    CGAffineTransform t = CGAffineTransformMakeScale(3.5, 3.5);
    t = CGAffineTransformTranslate(t, 0, -containerView.bounds.size.height/3.0);
    containerView.transform = t;
}

#pragma mark - Recording progress
-(void)showRecordingProgressOfDuration:(NSTimeInterval)duration
{
    self.guiRecordingProgressView.alpha = 1;
    
    [self.guiRecordingProgressView startTickingForDuration:duration
                                            ticksPerSecond:24];
}

-(void)hideRecordingProgressAnimated:(BOOL)animated
{
    self.guiRecordingProgressView.alpha = 0;
}

#pragma mark - EMTickingProgressDelegate
-(void)tickingProgressDidFinish
{
    // Tell the recorder that the duration of the recording ended.
    // This action is only related to the UI presented to the user
    // and it got nothing to do with the actual recording session
    // taking care of in the background by the capture session objects.
    // After this action, the ui should change to some UIActivity
    // indicating to the user to wait until the recording and processing
    // has really finished.
    [self.delegate controlSentAction:EMRecorderControlsActionRecordingDurationEnded
                                info:nil];
}

-(void)tickingProgressDidStart
{
}

-(void)tickingProgressWasCanceled
{
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onWeightSliderValueChanged:(UISlider *)slider
{
    _goodBackgroundWeight = slider.value;
    [self update];
}

@end
