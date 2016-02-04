//
//  EMEmusFeedVC.h
//  emu
//
//  Created by Aviv Wolf on 9/20/15.
//  Copyright © 2015 Homage. All rights reserved.
//
#import "EMTopVCProtocol.h"

@interface EMEmusFeedVC : UIViewController<
    EMTopVCProtocol
>

@property (nonatomic) NSString *originUI;

/**
 *  The feed UI states.
 */
typedef NS_ENUM(NSInteger, EMEmusFeedState){
    /**
     *  The user is browsing the emus.
     *  Pressing an emu will navigate to the selected emu screen.
     *  The related navigation bar will have two buttons:
     *     - A "Select" button for selecting emus.
     *     - A "Open recorder" button for retaking a pack or all emus.
     */
    EMEmusFeedStateBrowsing                     = 1000,
    
    /**
     *  The user pressed the "select" button and is now selecting Emus.
     *
     *  At the bottom of the screen replace footage + open recorder options will appear.
     *
     *  The UI will allow to toggle selection of emus when user presses emus.
     *  The UI will allow to toggle selection of a complete pack when user presses pack header cells.
     *
     *  The related navigation bar will have two buttons:
     *    - A "Cancel" button for returning to the browsing state without any action.
     *    - A "Clear" button removing all selections.
     */
    EMEmusFeedStateSelecting                    = 2000
};

@property (nonatomic) NSString *requestsPackageOID;
@property (nonatomic) NSString *requestsEmuOID;

-(void)consumeNavigationRequests;

-(void)restoreState;

@end
