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
    self = [self init];
    if (self) {
        _ctx = ctx;
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        _parseInfo = [NSMutableDictionary new];
        [self initDateFormatters];
    }
    return self;
}

-(void)initDateFormatters
{
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.locale =  [NSLocale localeWithLocaleIdentifier:@"en_US"];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    _dateFormatterFallback = [[NSDateFormatter alloc] init];
    _dateFormatterFallback.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    _dateFormatterFallback.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatterFallback.locale =  [NSLocale localeWithLocaleIdentifier:@"en_US"];
    [_dateFormatterFallback setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
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

-(NSDate *)parseDateOfString:(NSString *)dateString
{
    //"created_at" = "2014-03-09 14:30:13 UTC" <-- deprecated on server side
    //"created_at" = "2014-09-15T13:12:19.644Z" <-- changed to this on server side
    NSDate *date;
    
    dateString = [dateString substringToIndex:19];
    
    // Prase the string to nsdate using the dateFormatter
    date = [self.dateFormatter dateFromString:dateString];
    if (date) return date;
    
    // Failed parsing date. Try again using the fallback dateformatter.
    date = [self.dateFormatterFallback dateFromString:dateString];
    return date;
}

+(NSString *)parsedOID:(id)value
{
    NSString *oid = nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        oid = value[@"$oid"];
        if (oid == nil) oid = value[@"oid"];
        if (oid == nil) oid = value[@"_id"][@"$oid"];
    }
    if ([oid isKindOfClass:[NSString class]]) return oid;
    return nil;
}

+(NSDictionary *)prioritiesByOID:(NSArray *)prioritizedObjects
{
    NSMutableDictionary *priorities = [NSMutableDictionary new];
    NSInteger index = 0;
    for (id p in prioritizedObjects) {
        index++;
        NSString *oid = [HMParser parsedOID:p];
        if (oid) priorities[oid] = @(prioritizedObjects.count - index);
    }
    return priorities;
}

@end
