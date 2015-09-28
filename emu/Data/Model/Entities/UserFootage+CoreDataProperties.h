//
//  UserFootage+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "UserFootage.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserFootage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) NSNumber *framesCount;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSDate *timeTaken;

@end

NS_ASSUME_NONNULL_END
