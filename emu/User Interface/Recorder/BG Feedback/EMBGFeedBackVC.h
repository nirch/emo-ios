//
//  EMBGFeedBackViewController.h
//  emu
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMRecorderControlsDelegate.h"

@interface EMBGFeedBackVC : UIViewController

@property (nonatomic, weak) id<EMRecorderControlsDelegate> delegate;

@property (nonatomic) CGFloat goodBackgroundWeight;

#pragma mark - Background feedback
-(void)showBGFeedbackAnimated:(BOOL)animated;
-(void)hideBGFeedbackAnimated:(BOOL)animted;

#pragma mark - Recording progress
-(void)showRecordingProgressOfDuration:(NSTimeInterval)duration;
-(void)hideRecordingProgressAnimated:(BOOL)animated;

@end
