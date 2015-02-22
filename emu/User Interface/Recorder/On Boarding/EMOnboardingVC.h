//
//  EMOnBoardingVC.h
//  emu
//
//  Created by Aviv Wolf on 2/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMOnboardingDelegate.h"

#define EMOB_STAGES 5

@interface EMOnboardingVC : UIViewController

typedef NS_ENUM(NSInteger, EMOnBoardingStage) {
    EMOnBoardingStageWelcome                       = 0,
    EMOnBoardingStageAlign                         = 1,
    EMOnBoardingStageExtractionPreview             = 2,
    EMOnBoardingStageRecording                     = 3,
    EMOnBoardingStageDone                          = 4
};

@property (nonatomic) id<EMOnboardingDelegate> delegate;

@property (nonatomic, readonly) EMOnBoardingStage stage;

-(void)setOnBoardingStage:(EMOnBoardingStage)stage
                 animated:(BOOL)animated;

@end
