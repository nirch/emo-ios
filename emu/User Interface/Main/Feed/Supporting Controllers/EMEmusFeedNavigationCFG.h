//
//  EMEmusFeedNavigationCFG.h
//  emu
//
//  Configures the navigation bar on the 
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMNavBarConfigurationSource.h"

#define EMK_NAV_ACTION_SELECT @"nav action:select"
#define EMK_NAV_ACTION_RETAKE @"nav action:retake"

#define EMK_NAV_ACTION_CANCEL_SELECTION @"nav action:cancel selection"
#define EMK_NAV_ACTION_SELECT_PACK  @"nav action:select pack"

#define EMK_NAV_ACTION_NEW_TAKE @"nav action:new take"
#define EMK_NAV_ACTION_MY_TAKES @"nav action:my takes"

#define EMK_NAV_ACTION_RETAKE_CHOICE_PACKAGE @"nav action: retake package"

@interface EMEmusFeedNavigationCFG : NSObject<
    EMNavBarConfigurationSource
>

@end
