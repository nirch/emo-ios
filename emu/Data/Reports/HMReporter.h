//
//  HMAnalytics.h
//  emu
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


@interface HMAnalytics : NSObject

#

#pragma mark - Initialization
+(HMAnalytics *)sharedInstance;
+(HMAnalytics *)sh;

#pragma mark - Tracking
-(void)track

@end
