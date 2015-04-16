//
//  EMShareFBMessanger.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


#import "EMShareFBMessanger.h"
#import <Toast/UIView+Toast.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import "AppDelegate.h"

@interface EMShareFBMessanger()

@property (nonatomic) BOOL wasCanceled;

@end

@implementation EMShareFBMessanger


-(instancetype)init
{
    self = [super init];
    if (self) {
        // TODO: this use of "global" is ugly. Find a different solution if/when possible.
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        app.currentFBMSharer = self;
    }
    return self;
}

#pragma mark - Application flow
-(void)onAppDidBecomeActive
{
    if (self.wasCanceled) {
        [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
        [self.delegate sharerDidCancelWithInfo:self.info];
        return;
    }
    
    // Finish up
    [self.delegate sharerDidFinishWithInfo:self.info];
}

-(void)onFBMCancel
{
    self.wasCanceled = YES;
}


-(void)onFBMReply
{
}

-(void)onFBMOpen
{
    
}


#pragma mark - Share
-(void)share
{
    [super share];
    
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [emu animatedGifData];
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    FBSDKMessengerContext *context = app.fbContext;
    if ([FBSDKMessengerSharer messengerPlatformCapabilities] & FBSDKMessengerPlatformCapabilityAnimatedGIF)
    {
        self.wasCanceled = NO;
        FBSDKMessengerShareOptions *options = [FBSDKMessengerShareOptions new];
        options.context = context;
        
        [FBSDKMessengerSharer shareAnimatedGIF:gifData withOptions:options];
        [self.delegate sharerDidShareObject:self.objectToShare withInfo:self.info];
    } else {
        [self.delegate sharerDidFailWithInfo:self.info];
        [self messengerMissingMessage];
        return;
    }
}

-(void)messengerMissingMessage
{
    UIAlertController *alert = [UIAlertController new];
    alert.title = LS(@"FBM_MISSING_TITLE");
    alert.message = LS(@"FBM_MISSING_MESSAGE");
    
    // Install messenger action
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"FBM_INSTALL_OPTION")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                // Messenger isn't installed. Redirect the person to the App Store.
                                                [HMPanel.sh analyticsEvent:AK_E_FBM_INSTALL];
                                                NSString *iTunesLink = @"itms://itunes.apple.com/us/app/facebook-messenger/id454638411?mt=8";
                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                                            }]];
    
    // OK
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"FBM_MISSING_GOT_IT")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                [HMPanel.sh analyticsEvent:AK_E_FBM_DISMISSED_INSTALL];
                                            }]];
    
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

@end
