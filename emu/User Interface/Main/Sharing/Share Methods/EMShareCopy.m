//
//  EMShareCopy.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareCopy.h"
#import <Toast/UIView+Toast.h>
#import "HMPanel.h"

@implementation EMShareCopy

-(void)share
{
    [super share];
    
    if (self.shareOption == emkShareOptionAnimatedGif) {
        [self shareAnimatedGif];
    } else {
        [self shareVideo];
    }
}

-(void)shareAnimatedGif
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [emu animatedGifDataInHD:[emu shouldItRenderInHD]];
    
    // Copy the data to clipboard.
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setData:gifData forPasteboardType:@"com.compuserve.gif"];
    
    // Notify the user.
    if (self.selectionMessage) {
        [self.view makeToast:self.selectionMessage duration:1.0 position:CSToastPositionTop title:nil];
    } else {
        [self.view makeToast:LS(@"SHARE_TOAST_COPIED")];
    }
    
    // Done
    [self.delegate sharerDidShareObject:gifData withInfo:self.info];
}

-(void)shareVideo
{
    // Get the data of the video.
    Emuticon *emu = self.objectToShare;
    NSData *videoData = [emu videoData];
    
    // Copy the data to clipboard.
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setData:videoData forPasteboardType:@"public.mpeg-4"];
    
    // Notify the user.
    if (self.selectionMessage) {
        [self.view makeToast:self.selectionMessage duration:1.0 position:CSToastPositionTop title:nil];
    } else {
        [self.view makeToast:LS(@"SHARE_TOAST_COPIED")];
    }
    
    // Done
    [self.delegate sharerDidShareObject:videoData withInfo:self.info];
}

@end
