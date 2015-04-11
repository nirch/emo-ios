//
//  EMKeyboardVC.h
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMKeyboardContainerDelegate.h"

@interface EMEmusKeyboardVC : UIViewController

@property (nonatomic, weak) id<EMKeyboardContainerDelegate>delegate;

@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;

@end
