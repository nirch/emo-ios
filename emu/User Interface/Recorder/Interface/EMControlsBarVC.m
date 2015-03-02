//
//  ControlsBarViewController.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMControlsBarVC"

#import "EMUISound.h"
#import "EMControlsBarVC.h"
#import "HMBackgroundMarks.h"
#import "EMRecordButton.h"
#import "EMFlowButton.h"
#import "EMMessageButton.h"
#import "EMLabel.h"

@interface EMControlsBarVC () <
    EMCountDownDelegate
>

// Background detection messages
@property (weak, nonatomic) IBOutlet EMMessageButton *guiBadMessageButton;
@property (weak, nonatomic) IBOutlet EMMessageButton *guiGoodMessageButton;
@property (weak, nonatomic) IBOutlet UILabel *guiLongMessage;
@property (nonatomic) BOOL userPressedContinueAnyway;
@property (nonatomic) HMBGMark latestBGMark;
@property (nonatomic) HMBackgroundMarks *bgMarks;
@property (nonatomic) NSTimeInterval latestBGMarkTime;

// User buttons
@property (weak, nonatomic) IBOutlet EMFlowButton *guiContinueButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiNegativeButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiPositiveButton;

// Recording & Countdown
@property (weak, nonatomic) IBOutlet EMRecordButton *guiRecordButton;
@property (weak, nonatomic) IBOutlet EMLabel *guiCountdownLabel;
@property (nonatomic) NSInteger countDownNumber;



@end

@implementation EMControlsBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initState];
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self layoutFixesIfRequired];
}

-(void)initState
{
    self.userPressedContinueAnyway = NO;
    self.latestBGMark = HMBGMarkUnrecognized;
    self.latestBGMarkTime = 0;
    self.latestBGMarkTime = [[NSProcessInfo processInfo] systemUptime];
    self.bgMarks = [HMBackgroundMarks new];
    _state = EMRecorderControlsStateHidden;
}

-(void)initGUI
{
    [self hideAll];

    [self.guiContinueButton setTitle:nil forState:UIControlStateNormal];
    self.guiRecordButton.delegate = self;
    [self.guiBadMessageButton updateShowingIcon:YES
                                       positive:NO];
    [self.guiGoodMessageButton updateShowingIcon:YES
                                       positive:YES];
}

-(void)layoutFixesIfRequired
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight > 480.0) return;
    
    // Fu@#$%ing iPhone 4s needs special treatment of the layout.
    self.guiLongMessage.hidden = YES;
}



#pragma mark - States
-(void)setState:(EMRecorderControlsState)state
       animated:(BOOL)animated
{
    [self setState:state animated:animated info:nil];
}

-(void)setState:(EMRecorderControlsState)state
       animated:(BOOL)animated
           info:(NSDictionary *)info
{
    _state = state;
    [self handleStateAnimated:animated info:info];
}


-(void)handleStateAnimated:(BOOL)animated info:(NSDictionary *)info
{
    switch (self.state) {
        case EMRecorderControlsStateHidden:
            [self stateHiddenAnimated:animated];
            break;
            
        case EMRecorderControlsStateBackgroundDetection:
            [self stateBGDetectionAnimated:animated];
            break;
            
        case EMRecorderControlsStatePreparing:
            [self statePreparingWithInfo:info];
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
            
        case EMRecorderControlsStateReview:
            [self stateReviewAnimated:animated];
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
    self.guiGoodMessageButton.alpha = 0;
    self.guiBadMessageButton.alpha = 0;
    self.guiNegativeButton.alpha = 0;
    self.guiPositiveButton.alpha = 0;
    self.guiContinueButton.alpha = 0;
    self.guiRecordButton.alpha = 0;
    self.guiCountdownLabel.alpha = 0;
    self.guiLongMessage.alpha = 0;
}

-(void)stateHiddenAnimated:(BOOL)animated
{
    [self hideAll];
}

-(void)stateBGDetectionAnimated:(BOOL)animated
{
    [self hideAll];
    self.userPressedContinueAnyway = NO;
}

-(void)statePreparingWithInfo:(NSDictionary *)info
{
    [self hideAll];
    
    BOOL satisfactoryBGDetected = (info != nil && info[hmkInfoGoodBGSatisfied]);

    if (satisfactoryBGDetected) {
        self.guiGoodMessageButton.alpha = 1;
    } else {
        self.guiGoodMessageButton.alpha = 0;
    }
}


-(void)stateReadyToRecordAnimated:(BOOL)animated
{
    [self hideAll];
    
    self.guiRecordButton.alpha = 1;
    self.guiGoodMessageButton.alpha = 1;
    [self.guiGoodMessageButton setTitle:LS(@"RECORDER_MESSAGE_WHEN_READY")
                               forState:UIControlStateNormal];
    [self.guiGoodMessageButton updateShowingIcon:NO positive:YES];
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

-(void)stateReviewAnimated:(BOOL)animated
{
    [self hideAll];
    
    self.guiPositiveButton.alpha = 1;
    self.guiNegativeButton.alpha = 1;
    self.guiGoodMessageButton.alpha = 1;
    
    self.guiPositiveButton.positive = YES;
    self.guiNegativeButton.positive = NO;
    
    [self.guiGoodMessageButton updateShowingIcon:NO
                                        positive:YES];
    [self.guiGoodMessageButton setTitle:LS(@"RECORDER_MESSAGE_REVIEW_PREVIEW")
                               forState:UIControlStateNormal];
    
    [self.guiNegativeButton setTitle:LS(@"RECORDER_PREVIEW_TRY_AGAIN_BUTTON")
                            forState:UIControlStateNormal];

    [self.guiPositiveButton setTitle:LS(@"RECORDER_PREVIEW_CONFIRM")
                            forState:UIControlStateNormal];
    
    if (self.userPressedContinueAnyway) {
        self.guiLongMessage.alpha = 1;
        self.guiLongMessage.text = LS(@"RECORDER_PREVIEW_BAD_BACKGROUND_LONG_MESSAGE");
    }

}

-(void)stateDoneAnimated:(BOOL)animated
{
}

#pragma mark - Background detection messages
-(void)updateBackgroundInfo:(NSDictionary *)info
{
    if (self.state != EMRecorderControlsStateBackgroundDetection) {
        self.guiBadMessageButton.alpha = 0;
        return;
    }

    HMBGMark bgMark = [info[hmkInfoBGMark] integerValue];
    
    // If bad background mark is different than the last one,
    // update the message and the stored last mark.
    // But don't update the UI too often.
    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    NSTimeInterval timePassed = now - self.latestBGMarkTime;
    
    if (bgMark == HMBGMarkGood) {
        //
        // notified about good background
        // slowly hide the bad background message
        // if bad background message completely gone,
        // show the good background message
        //
        self.guiBadMessageButton.alpha = MAX(0, self.guiBadMessageButton.alpha - 0.3);
        if (self.guiBadMessageButton.alpha <= 0) {
            [self.guiContinueButton setTitle:LS(@"RECORDER_CONTINUE_BUTTON")
                                    forState:UIControlStateNormal];
            [self.guiGoodMessageButton setTitle:LS(@"RECORDER_BGM_GOOD")
                                       forState:UIControlStateNormal];
            self.guiGoodMessageButton.alpha = 1;
        }
        return;
    }
    
    if (bgMark == self.latestBGMark) {
        self.guiContinueButton.alpha = 1;
        self.guiBadMessageButton.alpha += 0.1;
        self.guiGoodMessageButton.alpha -= 0.5;
        return;
    }
    
    if (timePassed < 5) {
        if (timePassed > 2 && bgMark != self.latestBGMark) {
            self.guiBadMessageButton.alpha -= 0.1;
        }
        return;
    }
    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiBadMessageButton.alpha = 1;
    }];
    
    // Bad background message.
    NSString *messageKey = [self.bgMarks textKeyForMark:bgMark keyPrefix:@"RECORDER"];
    [self.guiBadMessageButton setTitle:LS(messageKey) forState:UIControlStateNormal];
    self.latestBGMark = bgMark;
    self.latestBGMarkTime = now;
    
    // Continue button
    self.guiContinueButton.alpha = 1;
    self.guiGoodMessageButton.alpha = 0;
    [self.guiContinueButton setTitle:LS(@"RECORDER_CONTINUE_ANYWAY_BUTTON")
                            forState:UIControlStateNormal];
}

#pragma mark - EMCountDownDelegate
-(void)countDownDidCountToNumber:(NSInteger)number
{
    if (self.state != EMRecorderControlsStateCountingDownToRecording)
        return;
    
    self.countDownNumber = number;
    [self handleStateAnimated:YES info:nil];
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
    self.guiGoodMessageButton.alpha = 0;
    self.guiBadMessageButton.alpha = 0;
    self.userPressedContinueAnyway = YES;
    [self.delegate controlSentAction:EMRecorderControlsActionContinueWithBadBackground
                                info:nil];
}

- (IBAction)onPressedRecordButton:(EMRecordButton *)recordButton
{
    if (recordButton.isCounting) {
        [self setState:EMRecorderControlsStateReadyToRecord animated:YES];
        [recordButton cancelCountDown];
        [EMUISound.sh playSoundNamed:SND_CANCEL];
        self.guiGoodMessageButton.alpha = 1;
    } else {
        [recordButton startCountDownFromNumber:3];
        [EMUISound.sh playSoundNamed:SND_PRESSED_BUTTON];
        self.guiGoodMessageButton.alpha = 0;
    }
}

- (IBAction)onPressedNegativeButton:(UIButton *)sender
{
    [self hideAll];
    [self.delegate controlSentAction:EMRecorderControlsActionNo
                                info:nil];
}

- (IBAction)onPressedPositiveButton:(UIButton *)sender
{
    [self hideAll];
    [self.delegate controlSentAction:EMRecorderControlsActionYes
                                info:nil];
}


@end
