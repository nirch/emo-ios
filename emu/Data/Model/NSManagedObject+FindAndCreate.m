//
//  NSManagedObject+FindAndCreate.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"NSManagedObject(FindAndCreate)"

#import "NSManagedObject+FindAndCreate.h"

@implementation NSManagedObject (FindAndCreate)

+(NSManagedObject *)findOrCreateEntityNamed:(NSString *)entityName
                                        oid:(NSString *)oid
                                    context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"oid=%@", oid];
    NSManagedObject *entity = [self fetchOrCreateEntityNamed:entityName
                                               withPredicate:predicate
                                                   inContext:context];
    [entity setValue:oid forKey:@"oid"];
    return entity;
}

+(id)fetchOrCreateEntityNamed:(NSString *)entityName
                withPredicate:(NSPredicate *)predicate
                    inContext:(NSManagedObjectContext *)context
{
    id entity;
    
    // Check if existing entity already exist in the store with the given ID.
    entity =  [self fetchSingleEntityNamed:entityName
                             withPredicate:predicate
                                 inContext:context];
    
    // Return it if found.
    if (entity)
        return entity;
    
    // Doesn't exist so should create a new one.
    entity = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                           inManagedObjectContext:context];
    return entity;
}

#pragma mark - Easier fetches
+(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName
                             withPredicate:(NSPredicate *)predicate
                                 inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"Error while searching for entity. %@",[error localizedDescription]);
        return nil;
    }
    return [self firstResult:results];
}


+(NSArray *)fetchEntityNamed:(NSString *)entityName
                       withPredicate:(NSPredicate *)predicate
                           inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"Error while searching for entity. %@",[error localizedDescription]);
        return nil;
    }
    return results;
}

+(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName
                                    withID:(NSString *)oid
                                 inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"oid=%@", oid];
    return [self fetchSingleEntityNamed:entityName
                          withPredicate:predicate
                              inContext:context];
}


+(NSManagedObject *)firstResult:(NSArray *)results
{
    if (!results) return nil;
    if (results.count > 0) {
        return results[0];
    }
    return nil;
}

@end
