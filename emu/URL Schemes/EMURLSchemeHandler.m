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
#import "EMDB.h"

@implementation EMURLSchemeHandler

+(BOOL)canHandleURL:(NSURL *)url
{
    NSString *scheme = [url scheme];
    
    // Emu Codes
    NSString *expectedScheme = [AppManagement.sh isTestApp]?@"emubetacodes":@"emucodes";
    if ([scheme isEqualToString:expectedScheme]) return YES;
    
    // Emu Open
    expectedScheme = [AppManagement.sh isTestApp]?@"emubetaopen":@"emuopen";
    if ([scheme isEqualToString:expectedScheme]) return YES;
    
    // Scheme not supported
    return NO;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if (![EMURLSchemeHandler canHandleURL:url]) {
        return NO;
    }
    
    NSString *scheme = [url scheme];

    // Handle code schemes
    if ([scheme containsString:@"codes"]) {
        NSString *code = [url host];
        if (code == nil || code.length<4) NO;
        [self redeemCode:code];
        return YES;
    }
    
    // Handle open schemes
    if ([scheme containsString:@"open"]) {
        NSString *whatToOpen = [url host];
        if ([whatToOpen isEqualToString:@"pack"]) {
            [self openPackWithOID:[[url path] substringFromIndex:1]];
            return YES;
        }
    }

    return NO;
}

-(void)redeemCode:(NSString *)code
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_CODE valueIfNotNil:code];
    [params addKey:AK_EP_LINK_TYPE valueIfNotNil:@"unhide packages"];
    [HMPanel.sh analyticsEvent:AK_E_DEEP_LINK_CODE info:params.dictionary];
    
    // Tell backend that a  'unhide packages' request is required.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredUnhidePackages
                                                        object:nil
                                                      userInfo:params.dictionary];

}

-(void)openPackWithOID:(NSString *)packOID
{
    if (packOID == nil) return;

    // Block the UI until finishing the flow of opening the pack
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationShowBlockingProgress
                                                        object:nil
                                                      userInfo:@{@"title":LS(@"PROGRESS_OPENING_PACK_TITLE")}];


    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        HMParams *params = [HMParams new];
        [params addKey:emkPackageOID value:packOID];
        [params addKey:@"autoNavigateToPack" value:@YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequestToOpenPackage
                                                            object:nil
                                                          userInfo:params.dictionary];
    });
}

@end
