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

@end
