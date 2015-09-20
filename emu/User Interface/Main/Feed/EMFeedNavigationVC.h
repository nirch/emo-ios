//
//  EMFeedNavigationVC.h
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMFeedNavigationVC : UIViewController

/**
 *  Instantiates a new instance of the feed screen navigation control
 *  (feed screen, indluding other navigated to screens like the emu / share screen)
 *  Uses theme colors as defined in EmuStyle.h
 *
 *  @return EMFeedNavigationVC
 */
+(EMFeedNavigationVC *)feedNavigationVC;


@end
