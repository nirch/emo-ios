//
//  HMGMError.h
//  emo
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HMGM_ERROR_DOMAIN @"it.homage.sdk.gm"

@interface HMGMError : NSError

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

/**
 *  Factory for the Green machine error object.
 *
 *  @param errorType    The error type of the error. See HMHErrorType enum of possible values.
 *  @param errorMessage A custom message specific for the error instance (optional).
 *
 *  @return Returns a new instance of HMGMError.
 */
+(HMGMError *)errorOfType:(HMGMErrorType)errorType
             errorMessage:(NSString *)errorMessage;

/**
 *  Factory for the Green machine error object.
 *
 *  @param errorType    The error type of the error. See HMHErrorType enum of possible values.
 *  @param errorMessage A custom message specific for the error instance (optional).
 *  @param userInfo     A dictionary of extra info fot the error instance (optional).
 *
 *  @return Returns a new instance of HMGMError.
 */
+(HMGMError *)errorOfType:(HMGMErrorType)errorType
             errorMessage:(NSString *)errorMessage
                 userInfo:(NSDictionary *)userInfo;

/**
 *  Initializer for the Green machine error object.
 *
 *  @param errorType    The error type of the error. See HMHErrorType enum of possible values.
 *  @param errorMessage A custom message specific for the error instance (optional).
 *  @param userInfo     A dictionary of extra info fot the error instance (optional).
 *
 *  @return Returns the initialized instance of HMGMError.
 */
-(HMGMError *)initWithErrorType:(HMGMErrorType)errorType
                   errorMessage:(NSString *)errorMessage
                       userInfo:(NSDictionary *)userInfo;

@end
