//
//  EmuticonDef.h
//  emu
//
//  Created by Aviv Wolf on 8/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Emuticon, Package;

@interface EmuticonDef : NSManagedObject

@property (nonatomic, retain) NSNumber * disallowedForOnboardingPreview;
@property (nonatomic, retain) NSNumber * dlProgress;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) id effects;
@property (nonatomic, retain) NSNumber * framesCount;
@property (nonatomic, retain) NSNumber * mixedScreenOrder;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * palette;
@property (nonatomic, retain) NSDate * patchedOn;
@property (nonatomic, retain) NSString * sourceBackLayer;
@property (nonatomic, retain) NSString * sourceFrontLayer;
@property (nonatomic, retain) NSString * sourceUserLayerDynamicMask;
@property (nonatomic, retain) NSString * sourceUserLayerMask;
@property (nonatomic, retain) NSNumber * thumbnailFrameIndex;
@property (nonatomic, retain) NSNumber * useForPreview;
@property (nonatomic, retain) NSString * prefferedWaterMark;
@property (nonatomic, retain) NSSet *emus;
@property (nonatomic, retain) Package *package;
@end

@interface EmuticonDef (CoreDataGeneratedAccessors)

- (void)addEmusObject:(Emuticon *)value;
- (void)removeEmusObject:(Emuticon *)value;
- (void)addEmus:(NSSet *)values;
- (void)removeEmus:(NSSet *)values;

@end
