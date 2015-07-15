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

#import <Foundation/Foundation.h>

@interface EMBackend : NSObject

#pragma mark - Initialization
+(EMBackend *)sharedInstance;
+(EMBackend *)sh;

#pragma mark - Web Service
@property (nonatomic, readonly) HMServer *server;

#pragma mark - Uploading
@property (nonatomic) AWSS3TransferManager *transferManager;


#pragma mark - Downloading resources
-(void)downloadResourcesForEmu:(Emuticon *)emu info:(NSDictionary *)info;
-(void)downloadResourcesForEmuDef:(EmuticonDef *)emuDef info:(NSDictionary *)info;
-(void)downloadZippedResourcesForPackage:(Package *)package;
-(void)bgDownloadZippedResourcesForPackage:(Package *)package
                         completionHandler:(void (^)())completionHandler
                               failHandler:(void (^)())failHandler;

#pragma mark - Background fetch
-(void)reloadPackagesInTheBackgroundWithNewDataHandler:(void (^)())newDataHandler
                                      noNewDataHandler:(void (^)())noNewDataHandler
                                    failedFetchHandler:(void (^)())failedFetchHandler;

-(void)notifyUserAboutUpdateForPackage:(Package *)package;

@end
