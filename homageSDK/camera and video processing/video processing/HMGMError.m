//
//  HMGMError.m
//  emu
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMGMError.h"

@implementation HMGMError

#pragma mark - Initializations
-(HMGMError *)initWithErrorType:(HMGMErrorType)errorType
                   errorMessage:(NSString *)errorMessage
                       userInfo:(NSDictionary *)userInfo
{
    return [super initWithErrorType:errorType
                             domain:HMGM_ERROR_DOMAIN
                       errorMessage:errorMessage
                           userInfo:userInfo];
}

@end
