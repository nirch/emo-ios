//
//  HMGMError.h
//  emu
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMError.h"

#define HMGM_ERROR_DOMAIN @"it.homage.sdk.greenmachine"

@interface HMGMError : HMError

/**
 *  Green machine error codes.
 */
typedef NS_ENUM(NSInteger, HMGMErrorType){

    /**
     *  General error.
     */
    HMGMErrorTypeGeneral                        = -1,

    /**
     *  A required resource file is missing / could not be found.
     */
    HMGMErrorTypeMissingResource                = 1000,
    HMGMErrorTypeInitializationFailed           = 1010,

};

-(HMGMError *)initWithErrorType:(HMGMErrorType)errorType
                   errorMessage:(NSString *)errorMessage
                       userInfo:(NSDictionary *)userInfo;

@end
