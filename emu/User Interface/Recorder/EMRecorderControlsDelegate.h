//
//  EMRecorderControlsDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


@protocol EMRecorderControlsDelegate <NSObject>

typedef NS_ENUM(NSInteger, EMRecorderControlsAction) {
    EMRecorderControlsActionContinueWithBadBackground   = 1000,
    EMRecorderControlsActionYes                         = 1100,
    EMRecorderControlsActionNo                          = 1200,
    EMRecorderControlsActionStartRecording              = 1300,
    EMRecorderControlsActionRecordingDurationEnded      = 1400
};

-(void)controlSentAction:(EMRecorderControlsAction)action
                    info:(NSDictionary *)info;

@end
