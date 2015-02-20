//
//  EMDB.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "NSManagedObject+FindAndCreate.h"

#import "Tag.h"
//#import "Tag+Logic.h"

#import "Emuticon.h"
#import "Emuticon+Logic.h"

#import "EmuticonDef.h"
#import "EmuticonDef+Logic.h"

#import "UserFootage.h"
//#import "UserFootage+Logic.h"

#import "AppCFG.h"
#import "AppCFG+Logic.h"

@interface EMDB : NSObject

// Core data stack
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic) NSManagedObjectContext *context;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Persistance / saving
-(void)save;
-(NSURL *)applicationDocumentsDirectory;

#pragma mark - Initialization
+(EMDB *)sharedInstance;
+(EMDB *)sh;


@end
