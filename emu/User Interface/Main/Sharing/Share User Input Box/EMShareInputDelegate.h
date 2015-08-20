//
//  EMShareInputDelegate.h
//  emu
//
//  Created by Aviv Wolf on 8/19/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMShareInputDelegate <NSObject>

-(void)shareInputWasCanceled;
-(void)shareInputWasConfirmedWithText:(NSString *)text;

@end
