//
//  HMJSONResponseSerializerWithData.h
//  Homage
//
//  Created by Yoav Caspin on 3/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "AFURLResponseSerialization.h"

/// NSError userInfo keys that will contain response data
static NSString * const JSONResponseSerializerWithDataKey = @"body";
static NSString * const JSONResponseSerializerWithBodyKey = @"statusCode";

@interface HMJSONResponseSerializerWithData : AFJSONResponseSerializer

@end