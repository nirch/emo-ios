//
//  EMDB.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMDB"

#import "EMDB.h"
#import "EMDB+Files.h"
#import "HMPanel.h"
#import "HMParser.h"
#import "AppManagement.h"
#import "MongoID.h"

@implementation EMDB

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Initialization
// A singleton
+(EMDB *)sharedInstance
{
    static EMDB *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMDB alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMDB *)sh
{
    return [EMDB sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        NSString *testString = @"2015-03-25 10:54:00 UTC";
        NSString *resultString;
        HMParser *parser = [HMParser new];
        NSDate *date = [parser parseDateOfString:testString];
        NSString *msg;

        self.timeStringForFileFormatter = [NSDateFormatter new];
        self.timeStringForFileFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        self.timeStringForFileFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        self.timeStringForFileFormatter.locale =  [NSLocale localeWithLocaleIdentifier:@"en_US"];
        self.timeStringForFileFormatter.dateFormat = @"HHmmss";

        // Test it
        resultString = [self.timeStringForFileFormatter stringFromDate:date];
        msg = [SF:@"Test time formatter: %@ %@ %@", testString, date, resultString];
        REMOTE_LOG(@"%@", msg);
        
        
        self.dateStringForFileFormatter = [NSDateFormatter new];
        self.dateStringForFileFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        self.dateStringForFileFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        self.dateStringForFileFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        self.dateStringForFileFormatter.dateFormat = @"yyyyMMdd";

        // Test it
        resultString = [self.dateStringForFileFormatter stringFromDate:date];
        msg = [SF:@"Test time formatter: %@ %@ %@", testString, date, resultString];
        REMOTE_LOG(@"%@", msg);
        
        // Default store name
        _storeName = @"emu";
    }
    return self;
}

#pragma mark - BSON Object ID
+(NSString *)generateOID
{
    ObjectID _id = [MongoID id];
    NSString *objectOIDString = [MongoID stringWithId:_id];
    return objectOIDString;
}

#pragma mark - Persistance
- (void)save {
    HMLOG(TAG, EM_DBG, @"EMDB will save.");
    REMOTE_LOG(@"EMDB will save.");
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            REMOTE_LOG(@"EMDB save unresolved error %@", [error localizedDescription]);
            HMLOG(TAG, EM_ERR, @"Unresolved error %@", error);
        }
    }
}

#pragma mark - Mocking & Tests
// Mocking & Tests
-(void)initFakeDBNamed:(NSString *)name
{
    _storeName = name;
}

-(void)deleteStoreWithError:(NSError **)error
{
    NSFileManager *fm = [NSFileManager defaultManager];
    error = nil;
    [fm removeItemAtPath:[[self storeURL] path] error:error];
}

#pragma mark - Core Data stack
-(NSURL *)storeURL
{
    // The group container url
    NSURL *groupURL = [EMDB rootURL];
    
    // The sqlite file
    NSURL *storeURL = [groupURL URLByAppendingPathComponent:[SF:@"%@.sqlite", self.storeName]];
    
    return storeURL;
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"emu" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    

    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    NSURL *storeURL = [self storeURL];
    
    // Auto light migration.
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption:@YES,
                              NSInferMappingModelAutomaticallyOption:@YES
                              };
    
    //
    // Add the persistent store.
    //
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        REMOTE_LOG(@"DB ERROR: %@", dict);
        if (AppManagement.sh.isTestApp) {
            abort();
        } else {
            // TODO: Handle error
        }
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    NSMergePolicy *mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSOverwriteMergePolicyType];
    _managedObjectContext.mergePolicy = mergePolicy;

    return _managedObjectContext;
}

-(NSManagedObjectContext *)context
{
    return [self managedObjectContext];
}


@end
