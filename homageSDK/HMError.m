//
//  HMGMError.m
//  emu
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMError.h"

@implementation HMError

#pragma mark - Factories
+(HMError *)errorOfType:(NSInteger)errorType
                 domain:(NSString *)domain
           errorMessage:(NSString *)errorMessage
{
    return [HMError errorOfType:errorType
                         domain:domain
                   errorMessage:errorMessage
                       userInfo:nil];
}

+(HMError *)errorOfType:(NSInteger)errorType
                 domain:(NSString *)domain
           errorMessage:(NSString *)errorMessage
               userInfo:(NSDictionary *)userInfo
{
    HMError *error = [[HMError alloc] initWithErrorType:errorType
                                                 domain:domain
                                           errorMessage:errorMessage
                                               userInfo:userInfo];
    return error;
}

#pragma mark - Initializations
-(id)initWithErrorType:(NSInteger)errorType
                domain:(NSString *)domain
          errorMessage:(NSString *)errorMessage
              userInfo:(NSDictionary *)userInfo
{
    // Gather some info
    NSMutableDictionary *info = [NSMutableDictionary new];
    info[NSLocalizedDescriptionKey] = errorMessage;
    [info addEntriesFromDictionary:userInfo?userInfo:@{}];
    
    // Initialize nserror object.
    self = [super initWithDomain:domain
                            code:errorType
                        userInfo:info];
    if (self) {
        // Do extra initializations here.
    }
    return self;
}

@end
