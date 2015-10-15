//
//  EMURLSchemeHandler.m
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMURLSchemeHandler.h"
#import "AppManagement.h"
#import "EMNotificationCenter.h"
#import "HMPanel.h"

@implementation EMURLSchemeHandler

+(BOOL)canHandleURL:(NSURL *)url
{
    NSString *scheme = [url scheme];
    NSString *expectedScheme = [AppManagement.sh isTestApp]?@"emubetacodes":@"emucodes";
    return [scheme isEqualToString:expectedScheme];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if (![EMURLSchemeHandler canHandleURL:url]) {
        return NO;
    }
    
    NSString *code = [url host];
    if (code == nil || code.length<4) NO;

    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_CODE valueIfNotNil:code];
    [params addKey:AK_EP_LINK_TYPE valueIfNotNil:@"unhide packages"];
    [HMPanel.sh analyticsEvent:AK_E_DEEP_LINK_CODE info:params.dictionary];

    // Tell backend that a  'unhide packages' request is required.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredUnhidePackages
                                                        object:nil
                                                      userInfo:params.dictionary];
    
    
    return YES;
}



@end
