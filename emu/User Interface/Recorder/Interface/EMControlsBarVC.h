//
//  ControlsBarViewController.h
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecorderControlsDelegate.h"

@interface EMControlsBarVC : UIViewController

@property (weak, nonatomic) id<EMRecorderControlsDelegate> delegate;

#pragma mark - States
/**
 *  The state of the UI.
 */
typedef NS_ENUM(NSInteger, EMRecorderControlsState){
    /**
     *  No controls are shown.
     */
    EMRecorderControlsStateHidden                         = 0,
    
    /**
     *  The interface shows good/bad background information to the user.
     */
    EMRecorderControlsStateBackgroundDetection            = 1,

    /**
     *  Waiting for everything to be set up for the prepared for recording state.
     */
    EMRecorderControlsStatePreparing                      = 2,
    
    /**
     *  A record button is displayed, allowing the user to start recording.
     */
    EMRecorderControlsStateReadyToRecord                  = 3,

    /**
     *  A countdown to the beginning of recording is shown/animated.
     *  when the user pressed the countdown, the recording is canceled.
     *  when the countdown is finished, recording will start.
     */
    EMRecorderControlsStateCountingDownToRecording        = 4,

    /**
     *  The interface shown while recording a video.
     */
    EMRecorderControlsStateRecording                      = 5,

    /**
     *  Finished the recording. Asks user for confirmation of the result,
     *  and also allowing the user to go back and reshoot.
     */
    EMRecorderControlsStateReview                         = 6,

    /**
     *  Done.
     */
    EMRecorderControlsStateVideoDone                      = 7
};

/**
 *  The current EMRecorderControlsState of the UI.
 */
@property (nonatomic, readonly) EMRecorderControlsState state;


/**
 *  Set the state of the UI.
 *
 *  @param state    The new EMRecorderControlsState to change to.
 *  @param animated Boolean value indicating if to change to the new state with animations.
 */
-(void)setState:(EMRecorderControlsState)state animated:(BOOL)animated;
-(void)setState:(EMRecorderControlsState)state animated:(BOOL)animated info:(NSDictionary *)info;


#pragma mark - Background detection
/**
 *  Information about latest background detection.
 *
 *
 *  @param info The info as a dictionary, including information about
 *          the mark of the good/bad background and the weight
 *          of the good background (0...1 value).
 */
-(void)updateBackgroundInfo:(NSDictionary *)info;

-(void)cancelCountdown;

@end
