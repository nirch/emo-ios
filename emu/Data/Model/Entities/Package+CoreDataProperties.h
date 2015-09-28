//
//  Package+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Package.h"

NS_ASSUME_NONNULL_BEGIN

@interface Package (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *alreadyUnzipped;
@property (nullable, nonatomic, retain) NSDate *firstPublishedOn;
@property (nullable, nonatomic, retain) NSString *iconName;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *notificationText;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSString *prefferedFootageOID;
@property (nullable, nonatomic, retain) NSNumber *preventVideoWaterMarks;
@property (nullable, nonatomic, retain) NSNumber *priority;
@property (nullable, nonatomic, retain) NSNumber *rendersCount;
@property (nullable, nonatomic, retain) NSString *requiredVersion;
@property (nullable, nonatomic, retain) NSNumber *sampledEmuCount;
@property (nullable, nonatomic, retain) NSString *sampledEmuResultOID;
@property (nullable, nonatomic, retain) id sharingHashtags;
@property (nullable, nonatomic, retain) NSNumber *shouldAutoDownload;
@property (nullable, nonatomic, retain) NSNumber *showOnPacksBar;
@property (nullable, nonatomic, retain) NSDate *timeUpdated;
@property (nullable, nonatomic, retain) NSNumber *viewedByUser;
@property (nullable, nonatomic, retain) NSString *zipppedPackageFileName;
@property (nullable, nonatomic, retain) NSString *bannerName;
@property (nullable, nonatomic, retain) NSString *bannerWideName;
@property (nullable, nonatomic, retain) NSString *posterName;
@property (nullable, nonatomic, retain) NSNumber *isFeatured;
@property (nullable, nonatomic, retain) NSSet<EmuticonDef *> *emuDefs;

@end

@interface Package (CoreDataGeneratedAccessors)

- (void)addEmuDefsObject:(EmuticonDef *)value;
- (void)removeEmuDefsObject:(EmuticonDef *)value;
- (void)addEmuDefs:(NSSet<EmuticonDef *> *)values;
- (void)removeEmuDefs:(NSSet<EmuticonDef *> *)values;

@end

NS_ASSUME_NONNULL_END
