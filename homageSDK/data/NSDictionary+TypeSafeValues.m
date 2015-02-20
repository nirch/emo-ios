//
//  NSDictionary+TypeSafeValues.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSDictionary+TypeSafeValues.h"

@implementation NSDictionary (TypeSafeValues)

-(NSString *)safeStringForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSString class]]) return value;
    return nil;
}

-(NSString *)safeOIDStringForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        value = value[@"$oid"];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}


-(NSNumber *)safeNumberForKey:(id)key
{
    id value = self[key];
    
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:value];
        if (number) return number;
    }
    return nil;
}

-(NSDecimalNumber *)safeDecimalNumberForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSDecimalNumber class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [NSDecimalNumber decimalNumberWithString:[value stringValue]];
    return nil;
}

-(NSNumber *)safeBoolNumberForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSNumber class]]) return @([value boolValue]);
    return @NO;
}


@end
