//
//  EMShareFile.m
//  emu
//
//  Created by Dan Gal on 3/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareFile.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Toast/UIView+Toast.h>

@interface EMShareFile()<
UIDocumentInteractionControllerDelegate,
MFMailComposeViewControllerDelegate
>

@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (weak, nonatomic) MFMailComposeViewController *picker;

@end

@implementation EMShareFile


-(void)share{
    
    [super share];
    
    NSURL *url = self.objectToShare;
    
    // open the sharing panel
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
    self.documentInteractionController.delegate = self;
    
    // Try to send using document interaction controller
    BOOL documentInteractionPresented = [self.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.viewController.view animated:YES];
    
    // If airdrop unsuccessful send through mail
    if (!documentInteractionPresented) {
        self.documentInteractionController.delegate = nil;
        self.documentInteractionController = nil;
        
        // Try using configured mail client instead.
        if([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
            mailCont.mailComposeDelegate = self;
            
            [mailCont setSubject:@"Emu Zip for debugging"];
            [mailCont setToRecipients:[NSArray arrayWithObject:@""]];
            [mailCont setMessageBody:@"Enjoy these images for they are cherished moments that will not return.." isHTML:NO];
            
            NSData *zipData = [NSData dataWithContentsOfURL:url];
            [mailCont addAttachmentData:zipData mimeType:@"application/zip" fileName:@"emu_debug.zip"];
            
            [self.viewController presentViewController:mailCont animated:YES completion:nil];
            self.picker = mailCont;
        }
    }
    
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
            break;
        case MFMailComposeResultSaved:
            //
            // Mail message saved as draft.
            //
            [self.view makeToast:LS(@"SHARE_TOAST_MAIL_SAVED")];
            break;
        case MFMailComposeResultSent:
            //
            // Sent succesfully
            //
            [self.view makeToast:LS(@"SHARE_TOAST_MAIL_SENT")];
            break;
        case MFMailComposeResultFailed:
            //
            // Failed :-(
            //
            [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
            break;
        default:
            //
            // Well, I don't know what happened. OK?!
            //
            [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
            break;
    }
}


-(void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    [self.view makeToast:[SF:@"Sent file using:%@", application]];
}


#pragma mark - UIDocumentInteractionControllerDelegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.viewController;
}


@end
