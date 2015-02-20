//
//  HMBasicParser.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"
#import "NSDictionary+TypeSafeValues.h"

#define ERROR_DOMAIN_PARSERS @"Parser error"

// If object with url_property is different than the new url parsed to info[key] then clear then clear the OBJECT.CACHE_PROPERTY
#define CLEAR_CACHE_CHECK(OBJECT, URL_PROPERTY, CACHE_PROPERTY, KEY) if (![OBJECT.URL_PROPERTY isEqualToString:[info stringForKey:KEY]]) OBJECT.CACHE_PROPERTY = nil


typedef NS_ENUM(NSInteger, HMParserErrorCode) {
    HMParserErrorUnimplemented,
    HMParserErrorUnexpectedData
};

@interface HMParser : NSObject

@property (nonatomic, readonly) NSDateFormatter *dateFormatter;
@property (nonatomic, readonly) NSDateFormatter *dateFormatterFallback;

-(id)initWithContext:(NSManagedObjectContext *)ctx;

// Reference to the context
@property (readonly, nonatomic, weak) NSManagedObjectContext *ctx;

// The object that should be parsed by the parser
@property (strong, nonatomic) id objectToParse;

// Array of all parsing errors
@property (nonatomic, readonly) NSMutableArray *errors;

// The last error
@property (nonatomic, readonly) NSError *error;

// Extra information the parser stores while parsing.
@property (nonatomic) NSMutableDictionary *parseInfo;

-(void)parse;

@end
