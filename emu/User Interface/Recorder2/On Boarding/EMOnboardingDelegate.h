//
//  EMOnBoardingDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@protocol EMOnboardingDelegate <NSObject>

-(void)onboardingDidGoBackToStageNumber:(NSInteger)stageNumber;
-(void)onboardingUserWantsToCancel;
-(void)onboardingWantsToSwitchCamera;

@end
