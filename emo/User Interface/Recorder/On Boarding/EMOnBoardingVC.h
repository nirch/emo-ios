//
//  EMOnBoardingVC.h
//  emo
//
//  Created by Aviv Wolf on 2/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMOnboardingDelegate.h"

#define EMOB_STAGES 6

@interface EMOnboardingVC : UIViewController

typedef NS_ENUM(NSInteger, EMOnBoardingStage) {
    EMOnBoardingStageWelcome                       = 0,
    EMOnBoardingStageAlign                         = 1,
    EMOnBoardingStageExtractionPreview             = 2,
    EMOnBoardingStageCountingDown                  = 3,
    EMOnBoardingStageRecording                     = 4,
    EMOnBoardingStageDone                          = 5
};

@property (nonatomic) id<EMOnboardingDelegate> delegate;

@property (nonatomic, readonly) EMOnBoardingStage stage;

-(void)setOnBoardingStage:(EMOnBoardingStage)stage
                 animated:(BOOL)animated;

@end
