//
//  UserFootage.h
//  emu
//
//  Created by Aviv Wolf on 2/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserFootage : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * framesCount;
@property (nonatomic, retain) NSString * oid;
@property (nonatomic, retain) NSDate * timeTaken;

@end
