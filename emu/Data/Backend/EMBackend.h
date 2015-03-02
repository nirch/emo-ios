//
//  EMBackend.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMBackend : NSObject

#pragma mark - Initialization
+(EMBackend *)sharedInstance;
+(EMBackend *)sh;

#pragma mark - Fetching data
-(void)refreshData;

@end