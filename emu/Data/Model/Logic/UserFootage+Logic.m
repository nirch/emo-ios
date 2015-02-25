//
//  UserFootage+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "UserFootage+Logic.h"
#import "EMDB.h"
#import "EMFiles.h"

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

+(UserFootage *)findWithID:(NSString *)oid
                   context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_USER_FOOTAGE
                                                               withID:oid
                                                            inContext:context];
    return (UserFootage *)object;
}

+(UserFootage *)userFootageWithInfo:(NSDictionary *)info
                            context:(NSManagedObjectContext *)context
{
    NSString *oid               = info[emkOID];
    NSNumber *numberOfFrames    = info[emkNumberOfFrames];
    NSNumber *duration          = info[emkDuration];
    NSDate *date                = info[emkDate];
    
    UserFootage *userFootage = [self findOrCreateWithID:oid
                                                context:context];
    userFootage.framesCount = numberOfFrames;
    userFootage.duration = duration;
    userFootage.timeTaken = date;
    return userFootage;
}

-(NSString *)pathForUserImages
{
    NSString *docsPath = [EMFiles docsPath];
    NSString *path = [docsPath stringByAppendingPathComponent:[SF:@"/%@", self.oid]];
    return path;
}

@end
