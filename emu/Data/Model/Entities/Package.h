//
//  Package.h
//  emu
//
//  Created by Aviv Wolf on 5/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmuticonDef;

@interface Package : NSManagedObject

@property (nonatomic, retain) NSNumber * alreadyUnzipped;
@property (nonatomic, retain) NSDate * firstPublishedOn;
@property (nonatomic, retain) NSString * iconName;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * notificationText;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSString * prefferedFootageOID;
@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) NSNumber * rendersCount;
@property (nonatomic, retain) NSString * requiredVersion;
@property (nonatomic, retain) NSNumber * sampledEmuCount;
@property (nonatomic, retain) NSString * sampledEmuResultOID;
@property (nonatomic, retain) NSNumber * showOnPacksBar;
@property (nonatomic, retain) NSDate * timeUpdated;
@property (nonatomic, retain) NSNumber * viewedByUser;
@property (nonatomic, retain) NSString * zipppedPackageFileName;
@property (nonatomic, retain) NSNumber * shouldAutoDownload;
@property (nonatomic, retain) NSSet *emuDefs;
@end

@interface Package (CoreDataGeneratedAccessors)

- (void)addEmuDefsObject:(EmuticonDef *)value;
- (void)removeEmuDefsObject:(EmuticonDef *)value;
- (void)addEmuDefs:(NSSet *)values;
- (void)removeEmuDefs:(NSSet *)values;

@end
