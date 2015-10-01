//
//  EMNavBarConfigurationSource.h
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@protocol EMNavBarConfigurationSource <NSObject>

#define EMK_NAV_ACTION_1 @"EM Nav bar action 1"
#define EMK_NAV_ACTION_2 @"EM Nav bar action 2"

#define EMK_NAV_ACTION_NAME @"nav action name"
#define EMK_NAV_ACTION_ICON @"nav action icon"
#define EMK_NAV_ACTION_TEXT @"nav action text"


-(NSDictionary *)navBarConfigurationForState:(NSInteger)state;

@end
