//
//  EMKBOptionsDrawer.h
//  emu
//
//  Created by Aviv Wolf on 7/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMInterfaceDelegate.h"

@interface EMKBOptionsDrawer : UIViewController

@property (nonatomic, weak) id<EMInterfaceDelegate> delegate;

@property (nonatomic, readonly) NSInteger prefferedRenderMediaType;

-(void)initializeState;

@end
