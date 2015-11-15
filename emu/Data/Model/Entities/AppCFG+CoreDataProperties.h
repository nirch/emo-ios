//
//  AppCFG+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 08/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AppCFG.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppCFG (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *baseResourceURL;
@property (nullable, nonatomic, retain) NSString *bucketName;
@property (nullable, nonatomic, retain) NSString *clientName;
@property (nullable, nonatomic, retain) NSDate *configUpdatedOn;
@property (nullable, nonatomic, retain) NSNumber *dataVersionForcedFetch;
@property (nullable, nonatomic, retain) NSNumber *defaultOutputVideoMaxFps;
@property (nullable, nonatomic, retain) NSNumber *deprecatedFootageForPack;
@property (nullable, nonatomic, retain) NSNumber *lastUpdateTimestamp;
@property (nullable, nonatomic, retain) NSDate *latestPackagePublishedOn;
@property (nullable, nonatomic, retain) id localization;
@property (nullable, nonatomic, retain) id mixedScreenEmus;
@property (nullable, nonatomic, retain) NSNumber *mixedScreenEnabled;
@property (nullable, nonatomic, retain) id mixedScreenPrioritizedEmus;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSNumber *onboardingPassed;
@property (nullable, nonatomic, retain) NSString *onboardingUsingPackage;
@property (nullable, nonatomic, retain) NSString *prefferedFootageOID;
@property (nullable, nonatomic, retain) id tweaks;
@property (nullable, nonatomic, retain) id uploadUserContent;
@property (nullable, nonatomic, retain) NSNumber *userAskedInMainScreenAboutAlerts;
@property (nullable, nonatomic, retain) NSNumber *userPrefferedShareType;
@property (nullable, nonatomic, retain) NSNumber *userViewedEmuScreenTutorial;
@property (nullable, nonatomic, retain) NSNumber *userViewedKBTutorial;
@property (nullable, nonatomic, retain) NSNumber *userViewedMainTutorial;
@property (nullable, nonatomic, retain) NSNumber *playUISounds;

@end

NS_ASSUME_NONNULL_END
