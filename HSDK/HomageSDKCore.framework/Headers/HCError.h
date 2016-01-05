//
//  HCError.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 15/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  HCError is the base class of all error reporing under the homage sdk framework.
 *  Derived from the NSError class.
 */
@interface HCError : NSError

/**
 *  A dictionary mapping error codes to error messages.
 */
@property (nonatomic) NSMutableDictionary *errorMessages;

/**
 *  Initialize error with extra arguments for error messages.
 *
 *  @param errorDomain error domain
 *  @param code        error code
 *  @param userInfo    (optional) extra user info
 *
 *  @return HCError
 */
-(id)initWithDomain:(NSString *)errorDomain code:(NSInteger)code userInfo:(NSDictionary *)userInfo;

/**
 *  Initialize error
 *
 *  @param code     error code
 *  @param userInfo (optional) extra user info
 *
 *  @return HCError
 */
-(id)initWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;

/**
 *  Initialize error messages for this error object.
 */
-(void)initErrorMessages;

@end
