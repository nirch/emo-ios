//
//  HMGMError.m
//  emo
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMGMError.h"

@implementation HMGMError

#pragma mark - Factories
+(HMGMError *)errorOfType:(HMGMErrorType)errorType
             errorMessage:(NSString *)errorMessage
{
    return [HMGMError errorOfType:errorType
                     errorMessage:errorMessage
                         userInfo:nil];
}

+(HMGMError *)errorOfType:(HMGMErrorType)errorType
             errorMessage:(NSString *)errorMessage
                 userInfo:(NSDictionary *)userInfo
{
    HMGMError *error = [[HMGMError alloc] initWithErrorType:errorType
                                               errorMessage:errorMessage
                                                   userInfo:userInfo];
    return error;
}

#pragma mark - Initializations
-(id)initWithErrorType:(HMGMErrorType)errorType
          errorMessage:(NSString *)errorMessage
              userInfo:(NSDictionary *)userInfo
{
    // Gather some info
    NSMutableDictionary *info = [NSMutableDictionary new];
    info[NSLocalizedDescriptionKey] = errorMessage;
    [info addEntriesFromDictionary:userInfo?userInfo:@{}];

    // Initialize nserror object.
    self = [super initWithDomain:HMGM_ERROR_DOMAIN
                            code:errorType
                        userInfo:info];
    if (self) {
        // Do extra initializations here.
    }
    return self;
}

@end
