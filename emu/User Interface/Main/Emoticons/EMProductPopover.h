//
//  EMProductPopoverVC.h
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMInterfaceDelegate.h"

#define emkUIPurchaseHDContent @"emk UI purchase HD content"

@interface EMProductPopover : UIViewController<UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) id<EMInterfaceDelegate>delegate;
@property (nonatomic) NSString *packageOID;
@property (nonatomic) NSString *originUI;

@end
