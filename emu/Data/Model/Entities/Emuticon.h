//
//  Emuticon.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmuticonDef, UserFootage;

@interface Emuticon : NSManagedObject

@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSNumber * usageCount;
@property (nonatomic, retain) NSNumber * isPreview;
@property (nonatomic, retain) EmuticonDef *emuticonDef;
@property (nonatomic, retain) UserFootage *userFootage;

@end
