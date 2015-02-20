//
//  UserFootage+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "UserFootage+Logic.h"
#import "NSManagedObject+FindAndCreate.h"

@implementation UserFootage (Logic)

#pragma mark - Find or create
+(UserFootage *)findOrCreateWithID:(NSString *)oid
                      context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_USER_FOOTAGE
                                                                   oid:oid
                                                               context:context];
    return (UserFootage *)object;
}

@end
