//
//  EMShareDocumentInteraction.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMShareDocumentInteraction"

@import AssetsLibrary;

#import "EMShareDocumentInteraction.h"
#import <Toast/UIView+Toast.h>

@interface EMShareDocumentInteraction() <
    UIDocumentInteractionControllerDelegate
>


@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic) NSString *willSendToApplication;
@property (nonatomic) NSTimer *timer;

@end

@implementation EMShareDocumentInteraction

-(void)share
{
    [super share];
    self.selectionTitle = LS(@"SHARE_SAVE_EMU_CHOICE_TITLE");
    self.selectionMessage = nil;
    [self shareSelection];
}


-(void)shareAnimatedGif
{
    // TODO: implement
}

-(void)shareVideo
{
    // Get the url to the video
    Emuticon *emu = self.objectToShare;
    NSURL *url = [emu videoURL];
    
    // Use a temp file with a more human readable name
    NSURL *tempURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:[SF:@"%@.mp4", emu.emuDef.name]];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtURL:tempURL error:nil];
    
    NSError *error;
    [fm linkItemAtURL:url toURL:tempURL error:&error];
    if (error) {
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
    
    // The document interaction controller
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:tempURL];
    self.documentInteractionController.delegate = self;
    self.documentInteractionController.UTI = @"public.mpeg-4";
    BOOL valid = [self.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    if (!valid) {
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        return;
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.viewController;
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    if (application) {
        self.willSendToApplication = application;
        self.info[AK_EP_RECOGNIZED_APPLICATION] = application;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    if (application) {
        self.willSendToApplication = application;
        self.info[AK_EP_RECOGNIZED_APPLICATION] = application;
    }
    [HMPanel.sh analyticsEvent:AK_E_SHARE_SUCCESS info:self.info];
}


//-(void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
//{
//    
//}

-(void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    [HMPanel.sh analyticsEvent:AK_E_SHARE_FILE_OPENED_DLG info:self.info];
}

-(void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [HMPanel.sh analyticsEvent:AK_E_SHARE_FILE_DISMISSED_DLG info:self.info];
    [self.delegate sharerDidFinishWithInfo:self.info];
}

@end
