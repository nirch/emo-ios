//
//  EMShareMail.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import MessageUI;

#import "EMShareMail.h"
#import <Toast/UIView+Toast.h>

@interface EMShareMail() <
    UINavigationControllerDelegate,
    MFMailComposeViewControllerDelegate
>

@property (nonatomic) MFMailComposeViewController *picker;

@end

@implementation EMShareMail

-(void)share
{
    [super share];
    [self shareSelection];
}


-(void)shareAnimatedGif
{
    [super shareAnimatedGif];

    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [emu animatedGifData];
    
    // First check if mail client configured correctly.
    if (![MFMailComposeViewController canSendMail]) {
        [self.view makeToast:LS(@"SHARE_TOAST_MAIL_CLIENT_NOT_CONFIGURED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    // Open the composer with the animated gif as attachment
    self.picker = [[MFMailComposeViewController alloc] init];
    //    self.picker.delegate = (id<UINavigationControllerDelegate>)self.viewController.navigationController;
    self.picker.mailComposeDelegate = self;
    [self.picker addAttachmentData:gifData
                          mimeType:@"image/gif"
                          fileName:[SF:@"%@.gif", emu.emuDef.name]];
    
    [self.viewController presentViewController:self.picker
                                      animated:YES
                                    completion:nil];
}


-(void)shareVideo
{
    [super shareVideo];
    
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *videoData = [emu videoData];
    
    // First check if mail client configured correctly.
    if (![MFMailComposeViewController canSendMail]) {
        [self.view makeToast:LS(@"SHARE_TOAST_MAIL_CLIENT_NOT_CONFIGURED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    // Open the composer with the animated gif as attachment
    self.picker = [[MFMailComposeViewController alloc] init];
    self.picker.mailComposeDelegate = self;
    [self.picker addAttachmentData:videoData
                          mimeType:@"public.mpeg-4"
                          fileName:[SF:@"%@.mp4", emu.emuDef.name]];
    
    [self.viewController presentViewController:self.picker
                                      animated:YES
                                    completion:nil];
}


-(void)shareText
{
    [super shareText];
    NSString *subject = self.objectToShare[@"subject"];
    NSString *body = self.objectToShare[@"body"];
    [self _shareContent:body subject:subject isHTML:NO];
}


-(void)shareHTML
{
    [super shareHTML];
    NSString *subject = self.objectToShare[@"subject"];
    NSString *body = self.objectToShare[@"body"];
    [self _shareContent:body subject:subject isHTML:YES];
}

-(void)_shareContent:(NSString *)contentBody subject:(NSString *)subject isHTML:(BOOL)isHTML
{
    // First check if mail client configured correctly.
    if (![MFMailComposeViewController canSendMail]) {
        [self.view makeToast:LS(@"SHARE_TOAST_MAIL_CLIENT_NOT_CONFIGURED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    self.picker = [[MFMailComposeViewController alloc] init];
    self.picker.mailComposeDelegate = self;
    
    [self.picker setSubject:subject];
    [self.picker setMessageBody:contentBody isHTML:isHTML];
    
    [self.viewController presentViewController:self.picker
                                      animated:YES
                                    completion:nil];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    // Dismiss the mail picker.
    [self.picker dismissViewControllerAnimated:YES completion:^{
        self.picker.delegate = nil;
        self.picker = nil;
    }];
    
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //
            // Canceled
            //
            [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
            [self.delegate sharerDidCancelWithInfo:self.info];
            break;
        case MFMailComposeResultSaved:
            //
            // Mail message saved as draft.
            //
            [self.view makeToast:LS(@"SHARE_TOAST_MAIL_SAVED")];
            [self.delegate sharerDidCancelWithInfo:self.info];
            break;
        case MFMailComposeResultSent:
            //
            // Sent succesfully
            //
            [self.view makeToast:LS(@"SHARE_TOAST_MAIL_SENT")];
            [self.delegate sharerDidShareObject:self.objectToShare
                                       withInfo:self.info];
            break;
        case MFMailComposeResultFailed:
            //
            // Failed :-(
            //
            [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
            [self.delegate sharerDidFailWithInfo:self.info];
            break;
        default:
            //
            // Well, I don't know what happened. OK?!
            //
            [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
            [self.delegate sharerDidCancelWithInfo:self.info];
            break;
    }
}

@end
