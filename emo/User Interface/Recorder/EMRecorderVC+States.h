//
//  EMRecorderVC+States.h
//  emo
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecorderVC.h"

@interface EMRecorderVC (States)

typedef NS_ENUM(NSInteger, EMRecorderState) {
    EMRecorderStateStarting                         = 0,
    EMRecorderStateBGDetectionShouldStart           = 1,
    EMRecorderStateBGDetectionInProgress            = 2,
    EMRecorderStateFGExtractionShouldStart          = 3,
    EMRecorderStateFGExtractionInProgress           = 4,
    EMRecorderStateRecordingCountDown               = 5,
    EMRecorderStateRecording                        = 6,
    EMRecorderStateDone                             = 7
};

// Recorder states
@property (readonly) EMRecorderState recorderState;

-(void)initState;
-(void)handleStateWithInfo:(NSDictionary *)info;

@end
