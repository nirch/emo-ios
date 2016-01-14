//
//  EMTickingProgressView.m
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMTickingProgressView"

#import "EMTickingProgressView.h"

@interface EMTickingProgressView()

@property (nonatomic, readwrite) NSInteger ticksPerSecond;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic) UIView *progressIndicator;
@property (nonatomic) NSDate *timeStarted;
@property (nonatomic) NSTimer *ticker;
@property (nonatomic) float progress;

@end

@implementation EMTickingProgressView

-(void)awakeFromNib
{
    [self initProgressIndicator];
    self.backgroundColor = [UIColor clearColor];
}

-(void)initProgressIndicator
{
    UIImage *image = [UIImage imageNamed:@"recordingProgress"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    self.progressIndicator = imageView;
    self.progress = 0;
    [self update];
    [self addSubview:self.progressIndicator];
}

-(void)startTickingForDuration:(NSTimeInterval)duration
                ticksPerSecond:(NSInteger)ticksPerSecond
{
    // Initialize if needed.
    if (self.progressIndicator == nil)
        [self initProgressIndicator];

    
    // Lets start the clocks.
    self.duration = duration;
    self.alpha = 0.3;
    self.timeStarted = [NSDate date];
    self.progress = 0;
    [self update];
    
    // Do a tick every 1/ticksPerSecond
    NSTimeInterval tickTime = 1.0 / (float)ticksPerSecond;
    self.ticker = [NSTimer scheduledTimerWithTimeInterval:tickTime
                                                   target:self
                                                 selector:@selector(onTick:)
                                                 userInfo:nil
                                                  repeats:YES];
    
    [self.delegate tickingProgressDidStart];
}

-(void)update
{
    CGRect f = self.bounds;
    CGFloat w = f.size.width * self.progress;
    f.size.width = w;
    self.progressIndicator.frame = f;
}

-(void)reset
{
    self.progress = 0;
    [self update];
}

-(void)done
{
    if (self.ticker) {
        [self.ticker invalidate];
        self.ticker = nil;
        [self.delegate tickingProgressDidFinish];
        [UIView animateWithDuration:1.0 animations:^{
            self.alpha = 0;
        }];
    }
}

-(void)onTick:(NSTimer *)timer
{
    // Update the progress according to time passed.
    NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:self.timeStarted];
    self.progress = MIN(timePassed / self.duration,1);
    [self update];
    
    // If we are over the duration, we are done.
    // Browsers!
    if (self.progress >= 1)
        [self done];
}

@end
