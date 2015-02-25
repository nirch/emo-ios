//
//  HMRecordButton.m
//  emu
//
//  Created by Aviv Wolf on 1/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecordButton.h"
#import "EmuStyle.h"

@interface EMRecordButton()

@property (atomic) NSInteger counter;
@property (atomic) NSTimer *timer;

@end

@implementation EMRecordButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    self.backgroundColor = [UIColor clearColor];
}


-(void)startCountDownFromNumber:(NSInteger)number
{
    if (self.timer)
        return;
    
    self.counter = number;
    [self.delegate countDownWillStartFromNumber:number];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(count:)
                                                userInfo:nil
                                                 repeats:YES];
}

-(void)cancelCountDown
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        [self.delegate countDownWasCanceled];
    }
}

-(BOOL)isCounting
{
    if (self.timer == nil) return NO;
    return self.timer.isValid && self.counter > 0;
}

-(void)count:(NSTimer *)timer
{
    self.counter--;
    if (self.counter <= 0 && timer.isValid) {
        // Finished counting.
        self.counter = 0;
        [self.delegate countDownDidFinish];
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.delegate countDownDidCountToNumber:self.counter];
}

@end
