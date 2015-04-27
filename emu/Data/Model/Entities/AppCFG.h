//
//  AppCFG.h
//  emu
//
//  Created by Aviv Wolf on 4/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AppCFG : NSManagedObject

@property (nonatomic, retain) NSString * baseResourceURL;
@property (nonatomic, retain) NSString * bucketName;
@property (nonatomic, retain) NSString * clientName;
@property (nonatomic, retain) NSDate * configUpdatedOn;
@property (nonatomic, retain) NSNumber * defaultOutputVideoMaxFps;
@property (nonatomic, retain) NSDate * latestPackagePublishedOn;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * onboardingPassed;
@property (nonatomic, retain) NSString * onboardingUsingPackage;
@property (nonatomic, retain) NSString * prefferedFootageOID;
@property (nonatomic, retain) id tweaks;
@property (nonatomic, retain) id uploadUserContent;
@property (nonatomic, retain) NSNumber * userAskedInMainScreenAboutAlerts;
@property (nonatomic, retain) NSNumber * userViewedEmuScreenTutorial;
@property (nonatomic, retain) NSNumber * userViewedKBTutorial;
@property (nonatomic, retain) NSNumber * userViewedMainTutorial;

@end
