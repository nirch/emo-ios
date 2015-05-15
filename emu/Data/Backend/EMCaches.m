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
-(void)cacheGifsForEmus:(NSArray *)emus
{
    if (emus == nil || emus.count < 1) return;
    for (Emuticon *emu in emus) {
        NSURL *animatedGifURL = [emu animatedGifURL];
        NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
        if (animGifData == nil) continue;
        FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
        if (animGif == nil) continue;
        [EMCaches.sh.gifsDataCache setObject:animGif forKey:[animatedGifURL description]];
        HMLOG(TAG, EM_DBG, @"Cached %@", emu.emuDef.name);
    }
}

-(void)removeCachedGifForEmu:(Emuticon *)emu
{
    if (emu == nil) return;
    NSString *animatedGifURLKey = [[emu animatedGifURL] description];
    if ([EMCaches.sh.gifsDataCache objectForKey:animatedGifURLKey]) {
        [EMCaches.sh.gifsDataCache removeObjectForKey:animatedGifURLKey];
    }
}

-(void)clearCachedGifs
{
    [EMCaches.sh.gifsDataCache removeAllObjects];
}

@end
