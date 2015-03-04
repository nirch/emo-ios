//
//  HMParams.m
//  emu
//
//  Created by Aviv Wolf on 3/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMParams.h"

@interface HMParams()

@property (nonatomic) NSMutableDictionary *storedParameters;

@end

@implementation HMParams

-(id)init
{
    self = [super init];
    if (self) {
        self.storedParameters = [NSMutableDictionary new];
    }
    return self;
}

-(void)addKey:(NSString *)key value:(id)value
{
    if (key == nil) return;
    if (value == nil) value = @"unknown";
    self.storedParameters[key] = value;
}

-(void)addKey:(NSString *)key valueIfNotNil:(id)value
{
    if (key == nil) return;
    if (value == nil) return;
    self.storedParameters[key] = value;
}

-(NSDictionary *)dictionary
{
    return [NSDictionary dictionaryWithDictionary:self.storedParameters];
}

@end
