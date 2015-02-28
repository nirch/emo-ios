//
//  EMRecorderDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@protocol EMRecorderDelegate <NSObject>

typedef NS_ENUM(NSInteger, EMRecorderFlowType){
    /**
     *  Recorder was opened for the onboarding experience.
     *  (happens as long as the user didn't finish
     *  onboarding for the first time).
     *
     *  In this flow:
     *      - Recorder can't be dismissed by the user.
     *      - Change camera button not available (only selfie allowed)
     *      - When user approves footage, it will be set as the preffered
     *        footage application wide for all available or future packages.
     *      - Will start rendering all emuticons when done.
     */
    EMRecorderFlowTypeOnboarding                     = 1000,
    
    /**
     *  Recorder opened to retake a footage for a package.
     *
     *  In this flow:
     *
     *  - If recorder dismissed before footage approved,
     *    will delete the footage and will do nothing after
     *    dismissing the recorder.
     *
     *  - If new footage approved, will delete package specific
     *    old footage and start rendering emuticons of package
     *    with the new footage.
     *
     *
     */
    EMRecorderFlowTypeRetakeForPackage               = 2000,
    
    /**
     *  Recorder opened to retake a footage for a specific emuticon.
     *
     *  In this flow:
     *
     *  - If recorder dismissed before footage approved,
     *    will delete the footage and will do nothing after
     *    dismissing the recorder.
     *
     *  - If new footage approved, will render emuticon with the footage
     *    and delete the temp footage files (no UI for using the same footage
     *    again anyway).
     *
     */
    EMRecorderFlowTypeRetakeForSpecificEmuticons     = 3000
};


-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType
                                      info:(NSDictionary *)info;

@end
