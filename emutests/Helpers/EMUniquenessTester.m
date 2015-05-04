//
//  EMUniquenessTester.m
//  emu
//
//  Created by Aviv Wolf on 5/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMUniquenessTester.h"


@interface EMUniquenessTester() {
    NSMutableDictionary *_d;
}

@end

@implementation EMUniquenessTester

-(instancetype)init
{
    self = [super init];
    if (self) {
        _d = [NSMutableDictionary new];
    }
    return self;
}

-(NSString *)testIdentifier:(id)identifier
{
    if ([identifier isKindOfClass:[NSDictionary class]]) {
        identifier = identifier[@"$oid"];
    }
    
    if (identifier == nil)
        return @"Unexpected identifier. Nil?";

    if (![identifier isKindOfClass:[NSString class]])
        return [NSString stringWithFormat:@"Unexpected identifier format: %@", [identifier description]];

    if (_d[identifier])
        return [NSString stringWithFormat:@"Identifier is not unique: %@", [identifier description]];

    _d[identifier] = @YES;
    return nil;
}

@end
