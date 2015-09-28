//
//  EmuticonDef+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
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
@property (nullable, nonatomic, retain) NSNumber *framesCount;
@property (nullable, nonatomic, retain) NSNumber *mixedScreenOrder;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSNumber *order;
@property (nullable, nonatomic, retain) NSString *palette;
@property (nullable, nonatomic, retain) NSDate *patchedOn;
@property (nullable, nonatomic, retain) NSString *prefferedWaterMark;
@property (nullable, nonatomic, retain) NSString *sourceBackLayer;
@property (nullable, nonatomic, retain) NSString *sourceFrontLayer;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerDynamicMask;
@property (nullable, nonatomic, retain) NSString *sourceUserLayerMask;
@property (nullable, nonatomic, retain) NSNumber *thumbnailFrameIndex;
@property (nullable, nonatomic, retain) NSNumber *useForPreview;
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