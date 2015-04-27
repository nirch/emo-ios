//
//  Emuticon.h
//  emu
//
//  Created by Aviv Wolf on 4/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmuticonDef;

@interface Emuticon : NSManagedObject

@property (nonatomic, retain) NSNumber * isPreview;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSString * prefferedFootageOID;
@property (nonatomic, retain) NSNumber * renderedSampleUploaded;
@property (nonatomic, retain) NSNumber * usageCount;
@property (nonatomic, retain) NSNumber * wasRendered;
@property (nonatomic, retain) NSNumber * rendersCount;
@property (nonatomic, retain) EmuticonDef *emuDef;

@end
