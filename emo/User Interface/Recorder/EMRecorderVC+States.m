//
//  EMRecorderVC+States.m
//  emo
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecorderVC+States.h"

#import "HMCaptureSession.h"

@interface EMRecorderVC()

// Recorder states
@property (readwrite) EMRecorderState recorderState;

@end

@implementation EMRecorderVC (States)

#pragma mark - States
-(void)initState
{
    self.recorderState = EMRecorderStateStarting;
}

-(void)handleStateWithInfo:(NSDictionary *)info
{
    [self handleStateWithInfo:info nextState:nil];
}

-(void)handleStateWithInfo:(NSDictionary *)info nextState:(NSNumber *)nextState
{
    if (nextState) {
        self.recorderState = (EMRecorderState)[nextState integerValue];
    }
    
    switch (self.recorderState) {
        case EMRecorderStateStarting:
            // Just started. Reset UI and prepare for starting
            // inspecting frames with background detection.
            [self statePrepareForBGDetection];
            break;
            
        case EMRecorderStateBGDetectionShouldStart:
            // Ready to start background detection.
            [self stateStartBGDetection];
            break;
            
        case EMRecorderStateBGDetectionInProgress:
            // If good background threshold satisfied, will prepare for FG extraction.
            [self stateBGDetectionInProgress:info];
            break;
            
        case EMRecorderStateFGExtractionShouldStart:
            // Ready to start FG extraction.
            [self stateStartFGExtraction];
            break;
            
        case EMRecorderStateFGExtractionInProgress:
            // Do nothing in this state.
            // It is upto the user to start the countdown to recording,
            // by pressing the record button.
            break;
            
        case EMRecorderStateRecordingCountDown:
            // If counted down to zero, will need to start recording.
            // If user canceled the countdown, will do nothing
            // and go back to the EMRecorderStateFGExtractionInProgress state.
            [self stateCountDownToRecording];
            break;
            
        case EMRecorderStateRecording:
            // TODO: implement.
            break;
            
        case EMRecorderStateDone:
            // TODO: implement.
            break;
            
    }
}

-(void)statePrepareForBGDetection
{
    // Set UI to initial state of the recorder.
    // ...
    
    // Change to the BG Detection should start state.
    [self handleStateWithInfo:nil nextState:@(EMRecorderStateBGDetectionShouldStart)];
}

-(void)stateStartBGDetection
{
    // Don't process frames, but check some frames and
    // and give them a good/bad background mark.
    self.captureSession.shouldProcessVideoFrames = NO;
    self.captureSession.shouldInspectVideoFrames = YES;
    self.recorderState = EMRecorderStateBGDetectionInProgress;
}

-(void)stateBGDetectionInProgress:(NSDictionary *)info
{
    if (info[hmkInfoGoodBGSatisfied] == nil) return;
    
    // Info provided indicates that a good background threshold was satisfied.
    // It is time to stop the background detection sampling and start
    // the foreground extraction algorithm.
    [self handleStateWithInfo:nil nextState:@(EMRecorderStateFGExtractionShouldStart)];
}

-(void)statePrepareForFGExtraction
{
}

-(void)stateStartFGExtraction
{
}

-(void)stateCountDownToRecording
{
}


@end
