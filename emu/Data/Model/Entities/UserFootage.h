//
//  UserFootage.h
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Emuticon, Tag;

@interface UserFootage : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * framesCount;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSDate * timeTaken;
@property (nonatomic, retain) NSSet *emus;
@property (nonatomic, retain) NSSet *tags;
@end

@interface UserFootage (CoreDataGeneratedAccessors)

- (void)addEmusObject:(Emuticon *)value;
- (void)removeEmusObject:(Emuticon *)value;
- (void)addEmus:(NSSet *)values;
- (void)removeEmus:(NSSet *)values;

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
