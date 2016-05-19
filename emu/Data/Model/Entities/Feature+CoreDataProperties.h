//
//  Feature+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 18/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Feature.h"

NS_ASSUME_NONNULL_BEGIN

@interface Feature (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSNumber *purchased;
@property (nullable, nonatomic, retain) NSString *pid;

@end

NS_ASSUME_NONNULL_END
