//
//  EMMessageButton.m
//  emu
//
//  Created by Aviv Wolf on 2/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMessageButton.h"

@implementation EMMessageButton

@synthesize positive = _positive;

-(void)updateShowingIcon:(BOOL)showingIcon
                positive:(BOOL)positive
{
    _positive = positive;
    NSString *imageName = nil;
    UIImage *image = nil;
    if (showingIcon) {
        imageName = positive? @"goodBGSmallIcon" : @"badBGSmallIcon";
        image = [UIImage imageNamed:imageName];
    }

    // Set/Unset the icon for the button.
    [self setImage:image forState:UIControlStateNormal];
}


@end
