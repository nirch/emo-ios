//
//  NSDictionary+TypeSafeValues.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface NSDictionary (TypeSafeValues)

-(NSString *)safeStringForKey:(id)key;
-(NSString *)safeOIDStringForKey:(id)key;
-(NSNumber *)safeNumberForKey:(id)key;
-(NSDecimalNumber *)safeDecimalNumberForKey:(id)key;
-(NSNumber *)safeBoolNumberForKey:(id)key;
-(NSNumber *)safeBoolNumberForKey:(id)key defaultsValue:(NSNumber *)defaultValue;
-(NSArray *)safeArrayOfIdsForKey:(id)key;

#pragma mark - With defaults
-(NSString *)safeStringForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary;
-(NSString *)safeOIDStringForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary;;
-(NSNumber *)safeNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary;;
-(NSDecimalNumber *)safeDecimalNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary;;
-(NSNumber *)safeBoolNumberForKey:(id)key defaultsDictionary:(NSDictionary *)defaultsDictionary;;
-(NSDictionary *)safeDictionaryForKey:(id)key defaultValue:(NSDictionary *)defaultValue;

@end
