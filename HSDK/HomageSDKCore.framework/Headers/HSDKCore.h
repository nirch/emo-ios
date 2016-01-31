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

/**
 *  NSString with the build number of HSDKCore
 */
@property (nonatomic, readonly) NSString *sdkVersionStr;

/**
 *  YES if should track events (like rendering). NO by default.
 */
@property (nonatomic, readonly) BOOL isTrackingEnabled;

/**
 *  YES if tracking is to the production env. NO by default.
 */
@property (nonatomic, readonly) BOOL isTrackingEnvProd;

/**
 *  The tracking identifier. This identifier is sent as part of the tracking events to identify the client.
 *  By default uses the containing app identifier. To use a different identifier call enableTrackingWithEnv:withTrackingIdentifier: when enabling tracking.
 */
@property (nonatomic, readonly) NSString *trackingIdentifier;


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

/**
 *  Enables the tracking of events in the SDK. Default is disabled.
 *
 *  @param isProduction BOOL determines to which environment should report (true for production, false for test)
 */
-(void)enableTrackingWithEnv:(BOOL)isProduction;

/**
 *  Enables the tracking of events in the SDK. Default is disabled.
 *
 *  @param isProduction BOOL determines to which environment should report (true for production, false for test)
 *  @param trackingIdentifier NSString provide a custom tracking identifier (e.g. host app name)
 */
-(void)enableTrackingWithEnv:(BOOL)isProduction withTrackingIdentifier:(NSString *)trackingIdentifier;

/**
 *  Disables the tracking of events in the SDK.
 */
-(void)disableTracking;

@end
