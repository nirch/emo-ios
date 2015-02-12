//
//  HMRecordButton.h
//  emo
//
//  Created by Aviv Wolf on 1/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMCountDownDelegate.h"

@interface EMRecordButton : UIButton

@property (weak, nonatomic) id<EMCountDownDelegate> delegate;

-(void)startCountDownFromNumber:(NSInteger)number;
-(void)cancelCountDown;
-(BOOL)isCounting;

@end
