//
//  Package.h
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Package : NSManagedObject

@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * timeUpdated;

@end
