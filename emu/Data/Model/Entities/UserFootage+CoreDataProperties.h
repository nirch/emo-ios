//
//  UserFootage+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 18/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "UserFootage.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserFootage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *capturedVideoAvailable;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) NSNumber *footageHeight;
@property (nullable, nonatomic, retain) NSNumber *footageWidth;
@property (nullable, nonatomic, retain) NSNumber *framesCount;
@property (nullable, nonatomic, retain) NSNumber *gifAvailable;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSNumber *pngSequenceAvailable;
@property (nullable, nonatomic, retain) NSDate *timeTaken;
@property (nullable, nonatomic, retain) NSNumber *audioAvailable;

@end

NS_ASSUME_NONNULL_END
