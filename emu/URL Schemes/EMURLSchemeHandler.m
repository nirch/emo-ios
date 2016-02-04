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
#import "EMBackend.h"

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

    // Joint Emu
    expectedScheme = [AppManagement.sh isTestApp]?@"jointemubeta":@"jointemu";
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
    if ([scheme containsString:@"open"] || [scheme containsString:@"jointemu"]) {
        NSString *whatToOpen = [url host];
        if ([whatToOpen isEqualToString:@"pack"]) {
            [self openPackWithOID:[[url path] substringFromIndex:1]];
            return YES;
        } else if ([whatToOpen isEqualToString:@"invite"]) {
            [self openInviteWithInviteCode:[[url path] substringFromIndex:1]];
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

-(void)openInviteWithInviteCode:(NSString *)inviteCode
{
    if (inviteCode == nil) return;
    
    // Block the UI until finishing the flow of opening the invite
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationShowBlockingProgress
                                                        object:nil
                                                      userInfo:@{@"title":LS(@"JOINT_EMU_LOADING")}];
    

    // First, force refresh data
    [EMBackend.sh updatePackagesWithCompletionHandler:^(BOOL success) {
        if (success == NO) {
            // Failed refetching packages.
            // TODO: handle this error.
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationUpdateBlockingProgress
                                                            object:nil
                                                          userInfo:@{@"title":LS(@"JOINT_EMU_LOADING_INVITATION")}];

        // First, check if local storage already has an emu created by this invitation code.
        Emuticon *emu = [Emuticon findWithInvitationCode:inviteCode context:EMDB.sh.context];
        [emu gainFocus];
        HMParams *params = [HMParams new];
        [params addKey:emkJEmuInviteCode value:inviteCode];

        NSString *notificationName = emu==nil ? emkDataRequestInviteCode:emkJointEmuNavigateToInviteCode;
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:nil
                                                          userInfo:params.dictionary];
    }];
}

@end
