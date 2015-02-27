//
//  EMShareDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMShareDelegate <NSObject>

@optional
-(NSString *)shareObjectIdentifier;

-(void)sharerDidShareObject:(id)sharedObject
                   withInfo:(NSDictionary *)info;

-(void)sharerDidCancelWithInfo:(NSDictionary *)info;

-(void)sharerDidFailWithInfo:(NSDictionary *)info;

@end
