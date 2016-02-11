//
//  EMMessageButton.h
//  emu
//
//  Created by Aviv Wolf on 2/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMButton.h"

@interface EMMessageButton : EMButton

@property (nonatomic) BOOL positive;

-(void)updateShowingIcon:(BOOL)showingIcon
                positive:(BOOL)positive;

@end
