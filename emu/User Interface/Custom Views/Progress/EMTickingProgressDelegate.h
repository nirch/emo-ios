//
//  EMTickingProgressDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@protocol EMTickingProgressDelegate <NSObject>

-(void)tickingProgressDidStart;
-(void)tickingProgressWasCanceled;
-(void)tickingProgressDidFinish;

@end
