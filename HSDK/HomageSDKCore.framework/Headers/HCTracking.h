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

#pragma mark - Tracking

/**
 *  Tracking an event.
 *  
 *  The method will first check if tracking was enabled on HSDKCore singletone. If so it will proceed with the tracking flow.
 *  For all reported evetns, host app and sdk version properties will be added.
 *  The tracking will done with an async HTTP call. The completion handler will be invoked after the call return.
 *  If tracking is disabled, reportEvent will return immediatly
 *
 *  @param event BOOL name of the event to track
 *  @param params NSDictionary parameters to track with the event
 *  @param completionHandler void (^)(BOOL success) will be invoked once the HTTP call returns
 */
+(void)reportEvent:(NSString *)event withParams:(NSDictionary *)params withCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
