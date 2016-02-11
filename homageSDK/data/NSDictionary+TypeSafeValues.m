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

-(NSDictionary *)safeDictionaryForKey:(id)key defaultValue:(NSDictionary *)defaultValue
{
    id value = self[key];
    if ([value isKindOfClass:[NSDictionary class]]) return value;
    return defaultValue;
}

-(NSArray *)safeArrayForKey:(id)key defaultValue:(NSArray *)defaultValue
{
    id value = self[key];
    if ([value isKindOfClass:[NSArray class]]) return value;
    return defaultValue;
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
    return nil;
}

-(NSNumber *)safeBoolNumberForKey:(id)key defaultsValue:(NSNumber *)defaultValue
{
    id value = self[key];
    if ([value isKindOfClass:[NSNumber class]]) return @([value boolValue]);
    return defaultValue;
}

-(NSArray *)safeArrayOfIdsForKey:(id)key
{
    NSMutableArray *idsArray = [NSMutableArray new];
    NSArray *array = self[key];
    if (![array isKindOfClass:[NSArray class]]) return @[];
    for (id value in array) {
        NSString *parsedID;
        if ([value isKindOfClass:[NSDictionary class]]) {
            parsedID = value[@"oid"];
            if (parsedID == nil) parsedID = value[@"$oid"];
        } else {
            parsedID = value;
        }
        if ([parsedID isKindOfClass:[NSString class]]) {
            [idsArray addObject:parsedID];
        }
    }
    return idsArray;
}

#pragma mark - With defaults
-(NSString *)safeStringForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary
{
    NSString *value = [self safeStringForKey:key];
    if (value == nil) {
        value = [defaultsDictionary safeStringForKey:key];
    }
    return value;
}

-(NSString *)safeOIDStringForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary
{
    NSString *value = [self safeOIDStringForKey:key];
    if (value == nil) {
        value = [defaultsDictionary safeOIDStringForKey:key];
    }
    return value;
}

-(NSNumber *)safeNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary
{
    NSNumber *value = [self safeNumberForKey:key];
    if (value == nil) {
        value = [defaultsDictionary safeNumberForKey:key];
    }
    return value;
}

-(NSDecimalNumber *)safeDecimalNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary
{
    NSDecimalNumber *value = [self safeDecimalNumberForKey:key];
    if (value == nil) {
        value = [defaultsDictionary safeDecimalNumberForKey:key];
    }
    return value;
}

-(NSNumber *)safeBoolNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary
{
    NSNumber *value = [self safeBoolNumberForKey:key];
    if (value == nil) {
        value = [defaultsDictionary safeBoolNumberForKey:key];
    }
    // If value is still nil, set as NO by default.
    if (value == nil) {
        value = @NO;
    }
    return value;
}




@end
