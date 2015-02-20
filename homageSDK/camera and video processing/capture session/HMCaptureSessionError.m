//
//  HMCaptureSessionError.m
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMCaptureSessionError.h"

@implementation HMCaptureSessionError

#pragma mark - Initializations
-(id)initWithErrorType:(HMCSErrorType)errorType
          errorMessage:(NSString *)errorMessage
              userInfo:(NSDictionary *)userInfo
{
    return [super initWithErrorType:errorType
                             domain:HMCS_ERROR_DOMAIN
                       errorMessage:errorMessage
                           userInfo:userInfo];
}


@end
