//
//  EMBackend.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMBackend"

#import "EMBackend.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMEmuticonsParser.h"
#import "EMAppCFGParser.h"
#import "EMPackagesParser.h"

#import "HMServer.h"
#import "HMServer+Packages.h"
#import "EMNotificationCenter.h"

@implementation EMBackend

#pragma mark - Initialization
// A singleton
+(EMBackend *)sharedInstance
{
    static EMBackend *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMBackend alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMBackend *)sh
{
    return [EMBackend sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        _server = [HMServer new];
        [self initObservers];
    }
    return self;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataRequired:)
                     name:emkDataRequiredPackages
                   object:nil];
    
    // Getting an update from the server with packages data.
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataUpdated:)
                     name:emkDataUpdatedPackages
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataRequiredPackages];
    [nc removeObserver:emkDataUpdatedPackages];
}

#pragma mark - Observers handlers
-(void)onPackagesDataRequired:(NSNotification *)notification
{
    // Making sure required paths exist.
    [EMDB ensureRequiredDirectoriesExist];
    
    // Fetching current info from server.
    [self.server refreshPackagesInfo];
    
    // Save it all
    [EMDB.sh save];
}


-(void)onPackagesDataUpdated:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // Error on packages data request to web service
        NSDictionary *info = @{@"error":notification.reportedError};
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIDataRefreshPackages object:nil userInfo:info];
        return;
    }
    
    // Refreshed packages data.
    // Iterate packages and download packages zip files.
    for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
//        if ([package shouldDownloadZippedPackage]) {
//            [self downloadResourcesForPackage:package];
//        } else if ([package shouldUnzipZippedPackage]) {
//            // Create resource directory for package.
//            
//            // Unzip resources to the directory.
//        }
    }
}


-(void)downloadResourcesForPackage:(Package *)package
{
    NSURL *url = [package urlForZippedResources];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
}











/*
-(void)parseAppCFG
{
    NSDictionary *json = [self jsonDataInLocalFile:@"appCFG"];
    
    // Parse the data
    EMAppCFGParser *parser = [[EMAppCFGParser alloc] initWithContext:EMDB.sh.context];
    parser.objectToParse = json;
    [parser parse];
}


-(void)parsePackagesMetaData
{
    // Parse the meta data of all packages.
    // This will be used later to look for the emuticons information
    // for each package.
    NSDictionary *json = [self jsonDataInLocalFile:@"packages"];
    EMPackagesParser *packagesParser = [[EMPackagesParser alloc] initWithContext:EMDB.sh.context];
    packagesParser.objectToParse = json;
    [packagesParser parse];
}


-(void)parsePackages
{
    // Parse the emuticon definitions of all known packages.
    NSArray *packages = [Package allPackagesInContext:EMDB.sh.context];
    for (Package *package in packages) {
        // Load and parse json related to package.
        [self parseDataForPackage:package];
    }
}


-(void)parseDataForPackage:(Package *)package
{
    // Parse emuticon definitions of passed package.
    NSString *jsonFileName = [package jsonFileName];
    NSDictionary *json = [self jsonDataInLocalFile:jsonFileName];
    EMEmuticonsParser *emuParser = [[EMEmuticonsParser alloc] initWithContext:EMDB.sh.context];
    emuParser.objectToParse = json;
    emuParser.package = package;
    [emuParser parse];
}


#pragma mark - JSON Serialization
-(NSDictionary *)jsonDataInLocalFile:(NSString *)fileName
{
    // Read emuticons json file
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    
    if (jsonData == nil) {
        HMLOG(TAG, EM_ERR, @"JSON data not found for %@", fileName);
        return nil;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"NSJSONSerialization failed for %@: %@", fileName, [error localizedDescription]);
        return nil;
    }
    return json;
}
*/

@end
