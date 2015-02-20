//
//  HMError.h
//  emu
//
//  Created by Aviv Wolf on 2/4/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
@interface HMError : NSError

/**
 *  Factory for the homage sdk error object.
 *
 *  @param errorType    The error type of the error.
 *  @param domain       The error domain string.
 *  @param errorMessage A custom message specific for the error instance (optional).
 *
 *  @return Returns a new instance of HMGMError.
 */
+(HMError *)errorOfType:(NSInteger)errorType
                 domain:(NSString *)domain
           errorMessage:(NSString *)errorMessage;

/**
 *  Factory for the homage sdk error object.
 *
 *  @param errorType    The error type of the error.
 *  @param domain       The error domain string.
 *  @param errorMessage A custom message specific for the error instance (optional).
 *  @param userInfo     A dictionary of extra info fot the error instance (optional).
 *
 *  @return Returns a new instance of HMGMError.
 */
+(HMError *)errorOfType:(NSInteger)errorType
                 domain:(NSString *)domain
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
-(HMError *)initWithErrorType:(NSInteger)errorType
                       domain:(NSString *)domain
                 errorMessage:(NSString *)errorMessage
                     userInfo:(NSDictionary *)userInfo;

@end
