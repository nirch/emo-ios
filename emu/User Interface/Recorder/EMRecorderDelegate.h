//
//  EMRecorderDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol EMRecorderDelegate <NSObject>


#define emkFirstTake @"firstTake"
#define emkRetakeAll @"retakeAll"
#define emkRetakePackageOID @"retakePackage"
#define emkRetakeEmuticonsOID @"retakeEmuticonsOID"
#define emkRetakeForHDEmu @"retakeForHDEmu"

/**
 * EMRecorderFlowTypeInvalid
 * EMRecorderFlowTypeOnboarding
 * EMRecorderFlowTypeRetakeAll
 * EMRecorderFlowTypeRetakeForPackage (deprecated)
 * EMRecorderFlowTypeRetakeForSpecificEmuticons - List of emus to retake.
 * EMRecorderFlowTypeNewTake - No specific emu to retake (just add to list of user takes)
 */
typedef NS_ENUM(NSInteger, EMRecorderFlowType){
    /**
     *  Invalid flow type.
     *  The recorder must have a valid defined flow type to function.
     */
    EMRecorderFlowTypeInvalid                     = 0,
    
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
     *  Recorder opened to retake the master footage.
     *
     *  In this flow:
     *
     *  - If recorder dismissed before footage approved,
     *    will delete the footage and will do nothing after
     *    dismissing the recorder.
     *
     *  - If new footage approved, will set the new footage as
     *    the master footage and clean all emuticons using the master footage.
     *    (cleaned emuticons will be rendered again with the new footage)
     *
     *
     */
    EMRecorderFlowTypeRetakeAll                     = 2000,

    // EMRecorderFlowTypeRetakeForPackage = 3000 (deprecated)
    
    /**
     *  Recorder opened to retake a footage for a list of specific emuticons.
     *  (remark: this flow is also good for retake for a single emu)
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
    EMRecorderFlowTypeRetakeForSpecificEmuticons     = 4000,
    
    /**
     *  Recorder opened to add a new take.
     */
    EMRecorderFlowTypeNewTake                        = 5000
    
};


/**
 *  The flow is completed and the recorder should be dismissed.
 *
 *  @param flowType The flow type of the recorder (see EMRecorderFlowType)
 *  @param info     Extra info to pass
 */
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType
                                      info:(NSDictionary *)info;

/**
 *  The user requested to dismiss the recorder in the middle of the flow.
 *  the recorder shouldn't have any effect and all temp files will be cleaned.
 *
 *  @param flowType The flow type of the recorder (see EMRecorderFlowType)
 *  @param info     Extra info to pass
 */
-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType
                                  info:(NSDictionary *)info;

@end
