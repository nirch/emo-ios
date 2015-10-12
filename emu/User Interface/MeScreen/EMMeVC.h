//
//  EMMeVC.h
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#define emkUIFavorites @"UI favorites"
#define emkUIRecentlyShared @"UI recently shared"
#define emkUIRecentlyViewed @"UI recently viewed"

@interface EMMeVC : UIViewController

/**
 *  The feed UI states.
 */
typedef NS_ENUM(NSInteger, EMMeState){
    EMMeStateNormal                     = 1000,
};


@end
