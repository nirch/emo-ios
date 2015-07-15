//
//  EMShareDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMDB.h"

@protocol EMShareDelegate <NSObject>

@optional
-(NSString *)shareObjectIdentifier;

// Sharing did happen.
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info;

// Sharing was cancelled.
-(void)sharerDidCancelWithInfo:(NSDictionary *)info;

// Sharing failed.
-(void)sharerDidFailWithInfo:(NSDictionary *)info;

// An optional call, just for finishing up when required.
-(void)sharerDidFinishWithInfo:(NSDictionary *)info;

// An optional call (in case long operation with progress started)
-(void)sharerDidStartLongOperation:(NSDictionary *)info label:(NSString *)label;

// An optional call (in case long operation with progress started)
-(void)sharerDidProgress:(float)progress info:(NSDictionary *)info;

// GIF / Video data should be shared.
-(EMMediaDataType)sharerDataTypeToShare;

@end
