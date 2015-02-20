//
//  EmuticonDef.h
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Emuticon, Tag;

@interface EmuticonDef : NSManagedObject

@property (nonatomic, retain) NSNumber * outputAnimGifMaxFPS;
@property (nonatomic, retain) NSDecimalNumber * duration;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * sourceBackLayer;
@property (nonatomic, retain) NSNumber * sourceBackLayerFramesCount;
@property (nonatomic, retain) NSString * sourceFrontLayer;
@property (nonatomic, retain) NSNumber * sourceFrontLayerFramesCount;
@property (nonatomic, retain) NSNumber * outputVideoMaxFPS;
@property (nonatomic, retain) NSString * sourceUserLayerMask;
@property (nonatomic, retain) Emuticon *emus;
@property (nonatomic, retain) Tag *packageTag;
@property (nonatomic, retain) NSSet *tags;
@end

@interface EmuticonDef (CoreDataGeneratedAccessors)

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
