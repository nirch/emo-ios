//
//  UserFootage.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FootageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserFootage : NSManagedObject<FootageProtocol>

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "UserFootage+CoreDataProperties.h"
