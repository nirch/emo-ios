//
//  EmuticonDef+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 11/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EmuticonDef.h"

NS_ASSUME_NONNULL_BEGIN

@interface EmuticonDef (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *disallowedForOnboardingPreview;
@property (nullable, nonatomic, retain) NSNumber *dlProgress;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) id effects;
@property (nullable, nonatomic, retain) NSNumber *emuHeight;
@property (nullable, nonatomic, retain) NSNumber *emuWidth;
@property (nullable, nonatomic, retain) NSNumber *framesCount;
@property (nullable, nonatomic, retain) id fullRenderCFG;
@property (nullable, nonatomic, retain) NSNumber *hdAvailable;
@property (nullable, nonatomic, retain) id jointEmu;
@property (nullable, nonatomic, retain) NSNumber *mixedScreenOrder;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSNumber *order;
@property (nullable, nonatomic, retain) NSString *palette;
@property (nullable, nonatomic, retain) NSDate *patchedOn;
@property (nullable, nonatomic, retain) NSString *prefferedWaterMark;
@property (nullable, nonatomic, retain) NSString *sourceBackLayer;
@property (nullable, nonatomic, retain) NSString *sourceBackLayer2X;
@property (nullable, nonatomic, retain) NSString *sourceFrontLayer;
@property (nullable, nonatomic, retain) NSString *sourceFrontLayer2X;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerDynamicMask;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerDynamicMask2X;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerMask;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerMask2X;
@property (nullable, nonatomic, retain) NSNumber *thumbnailFrameIndex;
@property (nullable, nonatomic, retain) NSNumber *useForPreview;
@property (nullable, nonatomic, retain) NSNumber *assumedUsersLayersWidth;
@property (nullable, nonatomic, retain) NSNumber *assumedUsersLayersHeight;
@property (nullable, nonatomic, retain) NSSet<Emuticon *> *emus;
@property (nullable, nonatomic, retain) Package *package;

@end

@interface EmuticonDef (CoreDataGeneratedAccessors)

- (void)addEmusObject:(Emuticon *)value;
- (void)removeEmusObject:(Emuticon *)value;
- (void)addEmus:(NSSet<Emuticon *> *)values;
- (void)removeEmus:(NSSet<Emuticon *> *)values;

@end

NS_ASSUME_NONNULL_END
