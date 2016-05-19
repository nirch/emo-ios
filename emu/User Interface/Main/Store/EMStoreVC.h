//
//  StoreVC.h
//  emu
//
//  Created by Aviv Wolf on 16/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  The feed UI states.
 */
typedef NS_ENUM(NSInteger, EMStoreState){
    EMStoreStateNormal                     = 1000,
};

@interface EMStoreVC : UIViewController

+(EMStoreVC *)storeVC;

@end
