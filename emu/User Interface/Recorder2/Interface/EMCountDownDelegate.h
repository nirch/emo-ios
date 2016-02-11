//
//  EMCountDownDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMCountDownDelegate <NSObject>

-(void)countDownWillStartFromNumber:(NSInteger)number;
-(void)countDownDidCountToNumber:(NSInteger)number;
-(void)countDownDidFinish;
-(void)countDownWasCanceled;

@end
