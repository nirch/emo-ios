//
//  HSDKCore.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 05/01/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HCTracking;

/**
 *  The environment the sdk
 */
typedef NS_ENUM(NSInteger, sdkENV) {
    /**
     *  Undefined. The SDK may raise exceptions / will block functionality when in this state.
     */
    sdkEnvUndefined      = 0,
    /**
     *  Development/test environment.
     */
    sdkEnvDev            = 1,
    /**
     *  Production environment. Use the SDK in this state only on production apps or beta apps on testflight.
     */
    sdkEnvProduction     = 10
};

/**
 *  Base singleton SDK object.
 */
@interface HSDKCore : NSObject

#pragma mark - Info
/**
 *  i386
 *  x86_64
 *  iphone
 *  ipad
 *  ipod
 */
@property (nonatomic, readonly) NSString *deviceType;

/**
 *  The gen of the device (internal apple name, not the commercial name of the device).
 *  For example, IPad 4(Wifi) will be returned as gen 3 because the internal name is iPad3,1
 */
@property (nonatomic, readonly) NSInteger deviceGen;

/**
 *  Returns YES if the device is considered too slow for recording 
 *  (this is just a recommendation. the sdk can still be configured to record in any mode).
 */
@property (nonatomic, readonly) BOOL tooSlowForRTBGRemoval;

/**
 *  NSString with the build number of HSDKCore
 */
@property (nonatomic, readonly) NSString *sdkVersionStr;

/**
 *  YES if tracking is to the production env. NO by default.
 */
@property (nonatomic, readonly) BOOL isTrackingEnvProd;

/**
 *  YES if tracking is enabled. YES after useInEnvironment: sets the environment to production or dev.
 */
@property (nonatomic, readonly) BOOL isTrackingEnabled;

/**
 *  The environment (production/dev) set for the SDK. Can be set using the useInEnvironment: method.
 */
@property (nonatomic, readonly) sdkENV environment;

/**
 *  Tracking object.
 */
@property (nonatomic, readonly) HCTracking *tracking;

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
 *  Sets the environment the SDK is used in.
 *  Until this method is called for the first time, some of the SDK functionality will be blocked.
 *  A good place to call this method is in application:didFinishLaunchingWithOptions: of the app using the SDK.
 *
 *  @param environment sdkENV environment.
 */
-(void)useInEnvironment:(sdkENV)environment;

/**
 *  The version string of the SDK.
 *
 *  @return NSString with the version string of the SDK in the format X.Y
 */
-(NSString *)versionString;

@end
