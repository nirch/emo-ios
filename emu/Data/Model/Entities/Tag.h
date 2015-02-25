//
//  Tag.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmuticonDef, UserFootage;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSNumber * isPackage;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) UserFootage *defaultUserFootage;
@property (nonatomic, retain) NSSet *emuDefs;
@property (nonatomic, retain) NSSet *packageEmus;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addEmuDefsObject:(EmuticonDef *)value;
- (void)removeEmuDefsObject:(EmuticonDef *)value;
- (void)addEmuDefs:(NSSet *)values;
- (void)removeEmuDefs:(NSSet *)values;

- (void)addPackageEmusObject:(EmuticonDef *)value;
- (void)removePackageEmusObject:(EmuticonDef *)value;
- (void)addPackageEmus:(NSSet *)values;
- (void)removePackageEmus:(NSSet *)values;

@end
