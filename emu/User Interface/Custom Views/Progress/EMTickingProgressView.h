//
//  EMTickingProgressView.h
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTickingProgressDelegate.h"

@interface EMTickingProgressView : UIView

/**
 *  The EMTickingProgressDelegate delegate.
 */
@property (nonatomic, weak) id<EMTickingProgressDelegate> delegate;

/**
 *  Number of ticks per second.
 */
@property (nonatomic, readonly) NSInteger ticksPerSecond;

/**
 *  The total duration the progress from 0 to 1 should take.
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 *  Set the value back to 0.
 */
-(void)reset;

/**
 * Stop showing progress.
 */
-(void)done;

/**
 *  Start animating the progress from 0 to 1 for the given duration.
 *
 *  @param duration       The duration in seconds that it should take to progress from 0 to 1
 *  @param ticksPerSecond The numbers of time the progress should update per second.
 */
-(void)startTickingForDuration:(NSTimeInterval)duration
                ticksPerSecond:(NSInteger)ticksPerSecond;

@end
