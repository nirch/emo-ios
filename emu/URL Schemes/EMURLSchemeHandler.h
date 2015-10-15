//
//  EMURLSchemeHandler.h
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMURLSchemeHandler : NSObject

/**
 *  Check if the EMURLSchemeHandler can handle the provided url.
 *
 *  @param url The NSURL to handle.
 */
+(BOOL)canHandleURL:(NSURL *)url;

/**
 *  Handle a supported url scheme.
 *
 *  @param application UIApplication
 *  @param url NSURL url to handle
 *  @param sourceApplication NSString the source application of this link
 *  @param annotation
 *
 *  @return YES if handled. No otherwise
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;


@end
