//
//  EMDownloadsManager.h
//  emu
//
//  Created by Aviv Wolf on 6/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define MAX_CONCURRENT_DOWNLOADS 8

@class EMDB;
@class AFHTTPSessionManager;

@interface EMDownloadsManager : NSObject

-(instancetype)initWithDB:(EMDB *)db session:(AFHTTPSessionManager *)session;
-(void)enqueueEmuOIDForDownload:(NSString *)emuOID withInfo:(NSDictionary *)info;


@end
