//
//  EMDB.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "NSManagedObject+FindAndCreate.h"

#import "Emuticon.h"
#import "Emuticon+Logic.h"
#import "Emuticon+JointEmuLogic.h"

#import "EmuticonDef.h"
#import "EmuticonDef+Logic.h"
#import "EmuticonDef+JointEmuLogic.h"

#import "UserFootage.h"
#import "UserTempFootage.h"
#import "PlaceHolderFootage.h"
#import "UserFootage+Logic.h"

#import "AppCFG.h"
#import "AppCFG+Logic.h"

#import "Package.h"
#import "Package+Logic.h"

// Keys for passing info around
#define emkPath                     @"path"
#define emkResourcesLocalPath       @"resources local path"
#define emkResourcesRemoteURL       @"resources remote url"
#define emkIndexPath                @"indexPath"
#define emkSender                   @"sender"
#define emkOID                      @"oid"
#define emkUUID                     @"uuid"
#define emkPackageOID               @"package oid"
#define emkEmuticonOID              @"emuticon oid"
#define emkJEmuOID                  @"joint emu oid"
#define emkUploadedFootage          @"uploaded footage"
#define emkJEmuSlot                 @"joint emu slot"
#define emkJEmuInviteCode           @"joint emu invite code"
#define emkJEmuCancelReason         @"joint emu cancel reason"
#define emkEmuticonDefOID           @"emuticon definition oid"
#define emkEmuticonDefName          @"emuticon definition name"
#define emkRenderInHD               @"render in hd"
#define emkRenderType               @"render type"
#define emkMediaType                @"media type"
#define emkFootageOID               @"footage oid"
#define emkOutputOID                @"output oid"
#define emkNumberOfFrames           @"number of frames"
#define emkDuration                 @"duration"
#define emkDedicatedFootage         @"dedicated footage"
#define emkDate                     @"date"
#define emkDebug                    @"debug"
#define emkDataAlreadyExists        @"data already exists"
#define emkURL                      @"url"
#define emkCaptureInfo              @"capture info"
#define emkError                    @"error"

typedef NS_ENUM(NSInteger, EMMediaDataType) {
    EMMediaDataTypeGIF      = 0,
    EMMediaDataTypeVideo    = 1
};


@interface EMDB : NSObject

// Core data stack
@property (readonly, strong) NSString *storeName;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic) NSManagedObjectContext *context;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSDictionary *cachedTweakedValues;

// Persistance / saving
-(void)save;

// Mocking & Tests
-(void)initFakeDBNamed:(NSString *)name;
-(void)deleteStoreWithError:(NSError **)error;

#pragma mark - Counting
+(NSInteger)countEntityNamed:(NSString *)entityName
                   predicate:(NSPredicate *)predicate
                   inContext:(NSManagedObjectContext *)context;

#pragma mark - Initialization
+(EMDB *)sharedInstance;
+(EMDB *)sh;

#pragma mark - BSON Object ID
+(NSString *)generateOID;

@end
