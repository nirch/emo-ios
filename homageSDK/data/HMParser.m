//
//  HMBasicParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMParser.h"


@implementation HMParser

-(id)initWithContext:(NSManagedObjectContext *)ctx
{
    self = [super init];
    if (self) {
        _ctx = ctx;
        _parseInfo = [NSMutableDictionary new];
        [self initDateFormatters];
    }
    return self;
}

-(void)initDateFormatters
{
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    _dateFormatterFallback = [[NSDateFormatter alloc] init];
    [_dateFormatterFallback setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss ' UTC'"];
}

-(void)parse
{
    NSError *error = [NSError errorWithDomain:ERROR_DOMAIN_PARSERS
                                         code:HMParserErrorUnimplemented
                                     userInfo:@{NSLocalizedDescriptionKey:@"parse not implemented"}];
    [self.errors addObject:error];
}

-(NSError *)error
{
    if (self.errors && self.errors.count > 0) return [self.errors lastObject];
    return nil;
}

@end
