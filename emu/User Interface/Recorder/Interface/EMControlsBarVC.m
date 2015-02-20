//
//  ControlsBarViewController.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMControlsBarVC"

#import "EMControlsBarVC.h"
#import "HMBackgroundMarks.h"
#import "EMRecordButton.h"

@interface EMControlsBarVC () <
    EMCountDownDelegate
>

@property (weak, nonatomic) IBOutlet UIButton *guiMessageButton;


// Background detection
@property (nonatomic) HMBGMark latestBGMark;
@property (nonatomic) HMBackgroundMarks *bgMarks;
@property (nonatomic) NSTimeInterval latestBGMarkTime;

// User buttons
@property (weak, nonatomic) IBOutlet UIButton *guiNegativeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiPositiveButton;
@property (weak, nonatomic) IBOutlet UIButton *guiContinueButton;
@property (weak, nonatomic) IBOutlet EMRecordButton *guiRecordButton;

// Countdown
@property (weak, nonatomic) IBOutlet UILabel *guiCountdownLabel;
@property (nonatomic) NSInteger countDownNumber;

@end

@implementation EMControlsBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initState];
    [self initGUI];
}

-(void)initState
{
    self.latestBGMark = HMBGMarkUnrecognized;
    self.latestBGMarkTime = 0;
    self.latestBGMarkTime = [[NSProcessInfo processInfo] systemUptime];
    self.bgMarks = [HMBackgroundMarks new];
    _state = EMRecorderControlsStateHidden;
}

-(void)initGUI
{
    self.guiMessageButton.alpha = 0;
    [self.guiContinueButton setTitle:nil forState:UIControlStateNormal];
    self.guiRecordButton.delegate = self;
}

#pragma mark - States
-(void)setState:(EMRecorderControlsState)state animated:(BOOL)animated
{
    _state = state;
    [self handleStateAnimated:animated];
}


-(void)handleStateAnimated:(BOOL)animated
{
    switch (self.state) {
        case EMRecorderControlsStateHidden:
            [self stateHiddenAnimated:animated];
            break;
            
        case EMRecorderControlsStateBackgroundDetection:
            [self stateBGDetectionAnimated:animated];
            break;
            
        case EMRecorderControlsStateReadyToRecord:
            [self stateReadyToRecordAnimated:animated];
            break;
            
        case EMRecorderControlsStateCountingDownToRecording:
            [self stateCountingDownAnimated:animated];
            break;
            
        case EMRecorderControlsStateRecording:
            [self stateRecordingAnimated:animated];
            break;
            
        case EMRecorderControlsStateVideoSaved:
            [self stateVideoSavedAnimated:animated];
            break;
            
        case EMRecorderControlsStateVideoDone:
            [self stateDoneAnimated:animated];
            break;
            
        default:
            break;
    }
}


-(void)hideAll
{
    self.guiNegativeButton.alpha = 0;
    self.guiPositiveButton.alpha = 0;
    self.guiMessageButton.alpha = 0;
    self.guiContinueButton.alpha = 0;
    self.guiRecordButton.alpha = 0;
    self.guiCountdownLabel.alpha = 0;
}

-(void)stateHiddenAnimated:(BOOL)animated
{
    [self hideAll];
}

-(void)stateBGDetectionAnimated:(BOOL)animated
{
    [self hideAll];
    
    self.guiContinueButton.alpha = 1;
}

-(void)stateReadyToRecordAnimated:(BOOL)animated
{
    [self hideAll];
    
    self.guiRecordButton.alpha = 1;
}

-(void)stateCountingDownAnimated:(BOOL)animated
{
    // Update the count down to recording
    self.guiCountdownLabel.text = [SF:@"%@", @(self.countDownNumber)];
    self.guiCountdownLabel.alpha = 1;
}

-(void)stateRecordingAnimated:(BOOL)animated
{
    // Hide the record button.
    self.guiCountdownLabel.text = nil;
    self.guiRecordButton.alpha = 0;
    
    // Notify the delegate that recording should start.
    [self.delegate controlSentAction:EMRecorderControlsActionStartRecording
                                info:nil];
}

-(void)stateVideoSavedAnimated:(BOOL)animated
{
}

-(void)stateDoneAnimated:(BOOL)animated
{
}

#pragma mark - Background detection messages
-(void)updateBackgroundInfo:(NSDictionary *)info
{
    if (self.state != EMRecorderControlsStateBackgroundDetection) {
        self.guiMessageButton.alpha = 0;
        return;
    }

    HMBGMark bgMark = [info[hmkInfoBGMark] integerValue];
    
    // Don't update the messages too often.
    
    // If bad background mark is different than the last one,
    // update the message and the stored last mark.
    // But don't update the UI too often.
    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    NSTimeInterval timePassed = now - self.latestBGMarkTime;
    
    HMLOG(TAG, DBG, @"BG Mark: %@", @(bgMark));

    if (bgMark == HMBGMarkGood) {
        self.guiMessageButton.alpha -= 0.4;
        self.guiContinueButton.alpha -= 0.4;
        return;
    }
    
    if (bgMark == self.latestBGMark) {
        self.guiMessageButton.alpha += 0.1;
        return;
    }
    
    if (timePassed < 5) {
        if (timePassed > 2 && bgMark != self.latestBGMark) {
            self.guiMessageButton.alpha -= 0.1;
        }
        return;
    }
    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiMessageButton.alpha = 1;
    }];
    
    // Bad background message.
    NSString *messageKey = [self.bgMarks textKeyForMark:bgMark keyPrefix:@"RECORDER"];
    [self.guiMessageButton setTitle:LS(messageKey) forState:UIControlStateNormal];
    self.latestBGMark = bgMark;
    self.latestBGMarkTime = now;
    self.guiContinueButton.alpha = 1;
}

#pragma mark - EMCountDownDelegate
-(void)countDownDidCountToNumber:(NSInteger)number
{
    if (self.state != EMRecorderControlsStateCountingDownToRecording)
        return;
    
    self.countDownNumber = number;
    [self handleStateAnimated:YES];
}

-(void)countDownWasCanceled
{
    self.guiCountdownLabel.text = nil;
}

-(void)countDownWillStartFromNumber:(NSInteger)number
{
    if (self.state != EMRecorderControlsStateReadyToRecord)
        return;
    
    self.countDownNumber = number;
    [self setState:EMRecorderControlsStateCountingDownToRecording
          animated:YES];
}

-(void)countDownDidFinish
{
    [self setState:EMRecorderControlsStateRecording
          animated:YES];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedContinueAnywayButton:(UIButton *)sender
{
    [self.delegate controlSentAction:EMRecorderControlsActionContinueWithBadBackground
                                info:nil];
}

- (IBAction)onPressedRecordButton:(EMRecordButton *)recordButton
{
    if (recordButton.isCounting) {
        [self setState:EMRecorderControlsStateReadyToRecord animated:YES];
        [recordButton cancelCountDown];
    } else {
        [recordButton startCountDownFromNumber:5];
    }
}



@end
