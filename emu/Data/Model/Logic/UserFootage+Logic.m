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

+(UserFootage *)masterFootage
{
    // Get the oid of the master footage from app configuration.
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSString *masterFootageOID = appCFG.prefferedFootageOID;
    if (masterFootageOID == nil) return nil;
    
    // Find and return the master footage object.
    return [self findWithID:masterFootageOID
                    context:EMDB.sh.context];
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

-(void)deleteAndCleanUp
{
    // Delete all footage files.
    [self cleanUp];
    
    // Delete the object.
    [self.managedObjectContext deleteObject:self];
}

-(void)cleanUp
{
    // Delete all footage files.
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[self pathForUserImages] error:nil];
}

@end
