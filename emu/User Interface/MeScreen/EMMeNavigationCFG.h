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

#define EMK_NAV_ACTION_LOGIN @"nav action:login"
#define EMK_NAV_ACTION_MY_TAKES @"nav action:my takes"

@interface EMMeNavigationCFG : NSObject<
    EMNavBarConfigurationSource
>

@end
