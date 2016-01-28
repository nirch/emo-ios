//
//  HSDKCore.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 05/01/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Base singleton SDK object.
 */
@interface HSDKCore : NSObject

#pragma mark - Info
@property (nonatomic, readonly) NSString *sdkVersionStr;
@property (nonatomic, readonly) NSString *appBundle;


#pragma mark - Initialization
/**
 *  Singleton of HSDKCore
 *
 *  @return New or existing singleton instance of HSDKCore
 */
+(instancetype)sharedInstance;

/**
 *  A shorter name of the sharedInstance method. Behaves exactly the same.
 *
 *  @return New or existing singleton instance of HSDKCore
 */
+(instancetype)sh;

/**
 *  The version string of the SDK.
 *
 *  @return NSString with the version string of the SDK in the format X.Y
 */
-(NSString *)versionString;

@end
