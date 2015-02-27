//
//  NSManagedObject+FindAndCreate.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (FindAndCreate)

+(NSManagedObject *)findOrCreateEntityNamed:(NSString *)entityName
                                        oid:(NSString *)oid
                                    context:(NSManagedObjectContext *)ctx;

#pragma mark - Easier fetches
+(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName
                             withPredicate:(NSPredicate *)predicate
                                 inContext:(NSManagedObjectContext *)context;


+(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName
                                    withID:(NSString *)oid
                                 inContext:(NSManagedObjectContext *)context;

+(NSArray *)fetchEntityNamed:(NSString *)entityName
               withPredicate:(NSPredicate *)predicate
                   inContext:(NSManagedObjectContext *)context;

@end
