//
//  EMTutorialVC.h
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMInterfaceDelegate.h"

@interface EMTutorialVC : UIViewController

@property (nonatomic, weak) id<EMInterfaceDelegate> delegate;

-(void)start;
-(void)finish;

@end
