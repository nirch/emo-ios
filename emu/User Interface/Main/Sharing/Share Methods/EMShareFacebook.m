//
//  EMFacebookShare.m
//  emu
//
//  Created by Aviv Wolf on 7/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareFacebook.h"
#import <Toast/UIView+Toast.h>
@import Social;

@implementation EMShareFacebook


-(void)share
{
    [super share];
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        [self.view makeToast:LS(@"SHARE_TOAST_FACEBOOK_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    [self shareSelection];
}

-(void)shareSelection
{
    switch (self.shareOption) {
        // Currently only share gif is implemented.
        case emkShareOptionAnimatedGif:
            [self shareAnimatedGif];
            break;

        default:
            [NSException raise:NSInvalidArgumentException
                        format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
            break;
    }
}

-(void)shareAnimatedGif
{
    [super shareAnimatedGif];
    [super uploadBeforeSharing];
}


-(void)shareAfterUploaded
{
    [super shareAfterUploaded];
    
    // Facebook composer
    SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [composer addURL:[NSURL URLWithString:self.sharedLink]];
    [composer setCompletionHandler:^(SLComposeViewControllerResult result) {
        [self.viewController dismissViewControllerAnimated:YES completion:^{
            if (result == SLComposeViewControllerResultCancelled) {
                [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
                [self.delegate sharerDidCancelWithInfo:self.info];
            } else if (result == SLComposeViewControllerResultDone) {
                [self.view makeToast:LS(@"SHARE_TOAST_SHARED")];
                [self.delegate sharerDidShareObject:self.sharedLink withInfo:self.info];
            } else {
                [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
                [self.delegate sharerDidFailWithInfo:self.info];
            }
            [self.delegate sharerDidFinishWithInfo:self.info];
        }];
    }];
    
    [self.viewController presentViewController:composer animated:YES completion:nil];
}

@end
