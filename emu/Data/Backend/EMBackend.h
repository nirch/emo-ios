//
//  EMBackend.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class HMServer;
@class Emuticon;
@class EmuticonDef;
@class Package;
@class AWSS3TransferManager;

#import <StoreKit/StoreKit.h>
#import <Foundation/Foundation.h>

@interface EMBackend : NSObject

#pragma mark - Initialization
+(EMBackend *)sharedInstance;
+(EMBackend *)sh;

#pragma mark - Web Service
@property (nonatomic, readonly) HMServer *server;

#pragma mark - Uploading
@property (nonatomic, readonly) AWSS3TransferManager *transferManager;

#pragma mark - In App Purchases
@property (nonatomic) SKProductsRequest *productsRequest;
@property (nonatomic) NSMutableDictionary *productsByPID;
@property (nonatomic) NSMutableDictionary *packOIDByPID;
@property (nonatomic) BOOL isAlreadyListeningToTransactions;

#pragma mark - Data updates and navigations
-(void)openEmuWithOID:(NSString *)emuOID message:(NSString *)message;

#pragma mark - Background fetch
-(void)reloadPackagesInTheBackgroundWithNewDataHandler:(void (^)())newDataHandler
                                      noNewDataHandler:(void (^)())noNewDataHandler
                                    failedFetchHandler:(void (^)())failedFetchHandler;

-(void)notifyUserAboutUpdateForPackage:(Package *)package;

#pragma mark - Update with completion handler
-(void)updatePackagesWithCompletionHandler:(void (^)(BOOL success))completionHandler;

#pragma mark - Migration
-(void)footagesMigrationIfRequired;

@end
