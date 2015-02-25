//
//  AppCFG.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AppCFG : NSManagedObject

@property (nonatomic, retain) NSNumber * animGifMaxFPS;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * videoMaxFPS;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * onboardingPassed;

@end
