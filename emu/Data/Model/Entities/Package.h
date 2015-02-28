//
//  Package.h
//  emu
//
//  Created by Aviv Wolf on 2/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmuticonDef;

@interface Package : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSString * prefferedFootageOID;
@property (nonatomic, retain) NSDate * timeUpdated;
@property (nonatomic, retain) NSSet *emuDefs;
@end

@interface Package (CoreDataGeneratedAccessors)

- (void)addEmuDefsObject:(EmuticonDef *)value;
- (void)removeEmuDefsObject:(EmuticonDef *)value;
- (void)addEmuDefs:(NSSet *)values;
- (void)removeEmuDefs:(NSSet *)values;

@end
