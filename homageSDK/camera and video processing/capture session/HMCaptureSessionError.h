//
//  HMCaptureSessionError.h
//  emu
//
//  Created by Aviv Wolf on 2/16/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMError.h"

#define HMCS_ERROR_DOMAIN @"it.homage.sdk.capturesession"

@interface HMCaptureSessionError : HMError

/**
 *  Capture session error codes.
 */
typedef NS_ENUM(NSInteger, HMCSErrorType){

    /**
     *  General error.
     */
    HMCSErrorTypeGeneral                        = -1,

    /**
     *  The capture session is in the wrong state for action.
     */
    HMCSErrorTypeWrongState                 = 1000,
    
};

/**
 *  Initialize capture session error
 *
 *  @param errorType    HMCSErrorType
 *  @param errorMessage The error message
 *  @param userInfo     Extra info for the error object.
 *
 *  @return HMCaptureSessionError instance.
 */
-(id)initWithErrorType:(HMCSErrorType)errorType

          errorMessage:(NSString *)errorMessage
              userInfo:(NSDictionary *)userInfo;

@end
