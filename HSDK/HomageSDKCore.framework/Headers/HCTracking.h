//
//  HCTracking.h
//  HomageSDKCore
//
//  Created by Nir Channes on 1/27/16.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  (optional) Tracking info that can be added to a tracking event.
 */
extern NSString* const hctTrackInfo;

/**
 *  HCTracking used for tracking SDK events.
 */
@interface HCTracking : NSObject

#pragma mark - Lifecycle
/**
 *  Tear down the tracking object.
 *  Call this when apropriate to remove any owned hard pointers, observers etc, so ARC will be able to release the object
 *  properly.
 */
-(void)tearDown;

#pragma mark - Tracking info
/**
 *  The identifier of the tracking object instance.
 *  (by default, will be the app's bundle id)
 */
@property (nonatomic, readonly) NSString *trackingIdentifier;

/**
 *  Returns YES if tracking is enabled in production env.
 *
 *  @return BOOL Yes/No if tracking is enabled in production env.
 */
-(BOOL)isTrackingEnvProduction;

#pragma mark - Tracking
/**
 *  Tracking an event (by reporting to the server).
 *  
 *  The method will first check if tracking was enabled on HSDKCore singletone. If so it will proceed with the tracking flow.
 *  For all reported evetns, host app and sdk version properties will be added.
 *  The tracking will done with an async HTTP/S call. The completion handler will be invoked after the call return.
 *  If tracking is disabled, the call to this method is ignored.
 *
 *  @param event NSString* name of the event to track
 *  @param params NSDictionary parameters to track with the event
 *  @param completionHandler void (^)(BOOL success) will be invoked if tracking is disabled or when the HTTP call returns/experience an error.
 */
-(void)reportEvent:(NSString *)event withParams:(NSDictionary *)params withCompletionHandler:(void (^)(BOOL success))completionHandler;

/**
 *  Finished a new render. Increase the counters.
 *  (will not report the counters to the server just yet. 
 *  reportFinishedRendersCount will report the counters to the server when the app will loose focus)
 */
-(void)trackFinishedARender;

@end
