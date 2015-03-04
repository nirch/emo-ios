//
//  HMParams.h
//  emu
//
//  Created by Aviv Wolf on 3/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@interface HMParams : NSObject

@property (nonatomic, readonly) NSDictionary *dictionary;

/**
 *  Creates a new HMParams object and fill it with key values from the given dictionary.
 *
 *  @param dictionary Key value pairs that will be inserted on initialization to the new HMParams object.
 *
 *  @return A new and populated HMParams object.
 */
+(HMParams *)paramsWithDictionary:(NSDictionary *)dictionary;

/**
 *  Add a key->value pair.
 *
 *  @param key   The key (as string) of the pair. If nil, will skip addition.
 *  @param value The value object. If nil, will add value as an empty string.
 */
-(void)addKey:(NSString *)key value:(id)value;

/**
 *  Add a key->value pair.
 *
 *  @param key   The key (as string) of the pair. If nil, will skip addition.
 *  @param value The value object. If nil, will skip addition.
 */
-(void)addKey:(NSString *)key valueIfNotNil:(id)value;

@end
