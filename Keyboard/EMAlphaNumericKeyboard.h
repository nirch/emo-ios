//
//  EMAlphaNumericKeyboard.h
//  emu
//
//  Created by Aviv Wolf on 4/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMKeyboardContainerDelegate.h"

@interface EMAlphaNumericKeyboard : UIViewController

@property (nonatomic, weak) id<EMKeyboardContainerDelegate>delegate;

@end
