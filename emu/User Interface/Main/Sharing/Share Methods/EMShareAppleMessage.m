//
//  EMShareAppleMessage.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import MessageUI;

#import "EMShareAppleMessage.h"
#import <Toast/UIView+Toast.h>

@interface EMShareAppleMessage() <
    MFMessageComposeViewControllerDelegate
>

@property (nonatomic) MFMessageComposeViewController *picker;

@end

@implementation EMShareAppleMessage

-(void)share
{
    [super share];
    [self shareSelection];
}

-(void)shareAnimatedGif
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [emu animatedGifDataInHD:[emu shouldItRenderInHD]];
    
    // Check if able to send text.
    if(![MFMessageComposeViewController canSendText]) {
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    // Show the compose view controller
    self.picker = [MFMessageComposeViewController new];
    self.picker.messageComposeDelegate = self;
    
    [self.picker addAttachmentData:gifData
                    typeIdentifier:@"com.compuserve.gif"
                          filename:[SF:@"%@.gif", emu.emuDef.name]];
    
    [self.viewController presentViewController:self.picker
                                      animated:YES
                                    completion:nil];
}


-(void)shareVideo
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *videoData = [emu videoData];
    
    // Check if able to send text.
    if(![MFMessageComposeViewController canSendText]) {
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    // Show the compose view controller
    self.picker = [MFMessageComposeViewController new];
    self.picker.messageComposeDelegate = self;
    
    [self.picker addAttachmentData:videoData
                    typeIdentifier:@"public.mpeg-4"
                          filename:[SF:@"%@.mp4", emu.emuDef.name]];
    
    [self.viewController presentViewController:self.picker
                                      animated:YES
                                    completion:nil];
}


-(void)messageComposeViewController:(MFMessageComposeViewController *)controller
                didFinishWithResult:(MessageComposeResult)result
{
    [self.picker dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultCancelled) {
        [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
        [self.delegate sharerDidCancelWithInfo:self.info];
    } else if (result == MessageComposeResultSent) {
        [self.view makeToast:LS(@"SHARE_TOAST_SHARED")];
        [self.delegate sharerDidShareObject:self.objectToShare
                                   withInfo:self.info];
    } else {
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
    }
}

@end
