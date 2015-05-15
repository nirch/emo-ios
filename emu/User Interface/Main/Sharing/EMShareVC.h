//
//  EMShareViewController.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMShareDelegate.h"

@interface EMShareVC : UIViewController

@property (nonatomic, weak) id<EMShareDelegate> delegate;
@property (nonatomic) BOOL allowFBExperience;

@end
