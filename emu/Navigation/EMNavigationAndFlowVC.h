//
//  MainNavigationVC.h
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMNavigationAndFlowVC : UIViewController

/**
 *  The state of the high level navigation flow of the app.
 */
typedef NS_ENUM(NSInteger, EMNavFlowState){
    
    /**
     *  The splash screen is displayed on laucnh.
     *  Waiting for several conditions to be met before dismissed.
     */
    EMNavFlowStateSplashScreen =                0,
    
    /**
     *  User received control of the flow of the app.
     *  User can navigate freely.
     */
    EMNavFlowStateUserControlsNavigation =      100,
    
    /**
     *  Opening the recorder for the first time for the onboarding flow.
     */
    EMNavFlowStateOpenRecorderForOnBoarding =   200,
    
    /**
     *  Opening the recorder for creating a new retake/footage.
     */
    EMNavFlowStateOpenRecorderForNewTake =      300
};

/**
 *  The current flow state.
 */
@property (nonatomic, readonly) EMNavFlowState flowState;


@end
