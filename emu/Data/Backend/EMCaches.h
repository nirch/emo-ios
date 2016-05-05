//
//  EMCaches.h
//  emu
//
//  Created by Aviv Wolf on 5/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class Emuticon;

#import <Foundation/Foundation.h>

@interface EMCaches : NSObject

@property (nonatomic, readonly) NSCache *gifsDataCache;

#pragma mark - Initialization
+(EMCaches *)sharedInstance;
+(EMCaches *)sh;

#pragma mark - Emus gifs cache.
-(void)clearCachedResultsForEmu:(Emuticon *)emu;
-(void)checkCacheStatus;
-(void)clearAllCache;
-(void)clearMemoryCache;

@end
