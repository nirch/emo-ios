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

@property (nonatomic) NSInteger counter;
@property (nonatomic) BOOL isNowCounting;

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
    self.counter = number;
    self.isNowCounting = YES;
    [self.delegate countDownWillStartFromNumber:number];
    [self count];
}

-(void)cancelCountDown
{
    self.isNowCounting = NO;
    [self.delegate countDownWasCanceled];
}

-(BOOL)isCounting
{
    return self.isNowCounting;
}

-(void)count
{
    if (self.counter <= 0) {
        // Finished counting.
        self.counter = 0;
        self.isNowCounting = NO;        
        [self.delegate countDownDidFinish];
    }
    
    // Still counting
    __weak EMRecordButton *weakSelf = self;
    dispatch_after(DTIME(1), dispatch_get_main_queue(), ^{
        if (!weakSelf.isNowCounting)
            return;

        weakSelf.counter--;
        [weakSelf.delegate countDownDidCountToNumber:self.counter];
        
        // Next tick.
        [weakSelf count];
    });
}

@end
