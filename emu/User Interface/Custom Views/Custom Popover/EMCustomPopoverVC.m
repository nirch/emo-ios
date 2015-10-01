//
//  EMCustomPopoverVC.m
//  emu
//
//  Created by Aviv Wolf on 9/30/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMCustomPopoverVC.h"

@interface EMCustomPopoverVC ()

@end

@implementation EMCustomPopoverVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.delegate = self;
    }
    return self;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Make it work on iPhone as a popover.
    return UIModalPresentationNone;
}

@end
