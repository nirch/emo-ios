//
//  EMOnBoardingVC.h
//  emu
//
//  Created by Aviv Wolf on 2/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMOnboardingDelegate.h"
#import "EMRecorderDelegate.h"

#define EMOB_STAGES 6

@interface EMOnboardingVC : UIViewController

typedef NS_ENUM(NSInteger, EMOnBoardingStage) {
    EMOnBoardingStageWelcome                       = 0,
    EMOnBoardingStageAlign                         = 1,
    EMOnBoardingStageExtractionPreview             = 2,
    EMOnBoardingStageRecording                     = 3,
    EMOnBoardingStageFinishingUp                   = 4,
    EMOnBoardingStageReview                        = 5
};

@property (nonatomic) id<EMOnboardingDelegate> delegate;
@property (nonatomic, readonly) EMOnBoardingStage stage;
@property (nonatomic) EMRecorderFlowType flowType;

-(void)setOnBoardingStage:(EMOnBoardingStage)stage
                 animated:(BOOL)animated;

@end
