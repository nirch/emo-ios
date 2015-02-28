//
//  AppCFG.h
//  emu
//
//  Created by Aviv Wolf on 2/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AppCFG : NSManagedObject

@property (nonatomic, retain) NSNumber * defaultOutputVideoMaxFps;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * onboardingPassed;
@property (nonatomic, retain) NSString * onboardingUsingPackage;
@property (nonatomic, retain) NSString * prefferedFootageOID;

@end
