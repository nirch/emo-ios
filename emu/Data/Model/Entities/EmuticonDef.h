//
//  EmuticonDef.h
//  emu
//
//  Created by Aviv Wolf on 3/19/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Emuticon, Package;

@interface EmuticonDef : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * framesCount;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * sourceBackLayer;
@property (nonatomic, retain) NSString * sourceFrontLayer;
@property (nonatomic, retain) NSString * sourceUserLayerMask;
@property (nonatomic, retain) NSNumber * thumbnailFrameIndex;
@property (nonatomic, retain) NSNumber * useForPreview;
@property (nonatomic, retain) NSSet *emus;
@property (nonatomic, retain) Package *package;
@end

@interface EmuticonDef (CoreDataGeneratedAccessors)

- (void)addEmusObject:(Emuticon *)value;
- (void)removeEmusObject:(Emuticon *)value;
- (void)addEmus:(NSSet *)values;
- (void)removeEmus:(NSSet *)values;

@end
