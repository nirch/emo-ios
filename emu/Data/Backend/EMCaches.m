//
//  EMCaches.m
//  emu
//
//  Created by Aviv Wolf on 5/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMCaches"

#import "EMCaches.h"
#import "EMDB.h"
#import <FLAnimatedImage.h>
#import <PINRemoteImage/PINRemoteImage.h>
#import <PINCache/PINCache.h>

@implementation EMCaches

#pragma mark - Initialization
// A singleton
+(EMCaches *)sharedInstance
{
    static EMCaches *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMCaches alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMCaches *)sh
{
    return [EMCaches sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        _gifsDataCache = [NSCache new];
    }
    return self;
}

#pragma mark - Requested caching
-(void)clearCachedResultsForEmu:(Emuticon *)emu
{
    PINRemoteImageManager *rm = [PINRemoteImageManager sharedImageManager];
    
    // Remove animated gif result from the cache
    NSURL *animatedGifURL = emu.animatedGifURL;
    NSString *gifKey = [animatedGifURL description];
    [rm.cache removeObjectForKey:gifKey];
    
    // Remove thumb image
    NSURL *thumbURL = emu.thumbURL;
    NSString *thumbKey = [thumbURL description];
    [rm.cache removeObjectForKey:thumbKey];
}

-(void)clearAllCache
{
    PINRemoteImageManager *rm = [PINRemoteImageManager sharedImageManager];
    [rm.cache removeAllObjects:^(PINCache * _Nonnull cache) {
        // Cleared all PINCache.
    }];
}

@end
