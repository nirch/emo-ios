//
//  EMDownloadsManager.m
//  emu
//
//  Created by Aviv Wolf on 6/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMDownloadsManager"

#import "EMDownloadsManager.h"
#import "EMDB.h"

#define MAX_CONCURRENT_DOWNLOADS 4

@interface EMDownloadsManager()

@property (nonatomic) NSMutableDictionary *waitingForDownloadEmusPool;
@property (nonatomic) NSMutableDictionary *downloadingEmusPool;
@property EMDB *db;

@end

@implementation EMDownloadsManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self finalizeInitializations];
    }
    return self;
}

-(instancetype)initWithDB:(EMDB *)db
{
    self = [super init];
    if (self) {
        self.db = db;
        [self finalizeInitializations];
    }
    return self;
}

-(void)finalizeInitializations
{
    if (self.db == nil) self.db = EMDB.sh;
}

/**
 This method accesses EMDB. Call this only on the main thread!
 */
-(void)enqueueEmuOIDForDownload:(NSString *)emuOID withInfo:(NSDictionary *)info
{
    Emuticon *emu = [Emuticon findWithID:emuOID context:self.db.context];
    if (emu == nil) return;
    HMLOG(TAG, EM_VERBOSE, @"Should DLR for emu:%@", emuOID);
}



@end
