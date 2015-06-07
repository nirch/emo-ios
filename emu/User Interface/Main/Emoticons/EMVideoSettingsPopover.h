//
//  EMVideoSettingsPopover.h
//  emu
//
//  Created by Aviv Wolf on 6/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class Emuticon;

#import <UIKit/UIKit.h>

@interface EMVideoSettingsPopover : UIViewController<UIPopoverPresentationControllerDelegate>

@property (nonatomic) Emuticon *emu;

-(void)updateUI;

@end
