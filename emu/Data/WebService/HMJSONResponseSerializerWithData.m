//
//  HMJSONResponseSerializerWithData.m
//  Homage
//
//  Created by Yoav Caspin on 3/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMJSONResponseSerializerWithData.h"

@implementation HMJSONResponseSerializerWithData

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id JSONObject = [super responseObjectForResponse:response data:data error:error]; // may mutate `error`
    
    if (*error != nil) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        [userInfo setValue:dataDictionary forKey:JSONResponseSerializerWithDataKey];
        [userInfo setValue:[response valueForKey:JSONResponseSerializerWithBodyKey] forKey:JSONResponseSerializerWithBodyKey];
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
        (*error) = newError;
    }
    
    return JSONObject;
}

@end