//
//  EMShareSaveToCameraRoll.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import AssetsLibrary;

#import "EMShareSaveToCameraRoll.h"
#import <Toast/UIView+Toast.h>

@implementation EMShareSaveToCameraRoll

-(void)share
{
    [super share];

    self.selectionTitle = LS(@"SHARE_SAVE_EMU_CHOICE_TITLE");
    self.selectionMessage = nil;
    [self shareSelection];
}

-(void)shareAnimatedGif
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [NSData dataWithContentsOfFile:[emu animatedGifPath]];

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:gifData
                                     metadata:nil
                              completionBlock:^(NSURL *assetURL, NSError *error) {
                                  if (error) {
                                      [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
                                      [self.delegate sharerDidFailWithInfo:self.info];
                                      return;
                                  }
                                  // Notify the user.
                                  [self.view makeToast:LS(@"SHARE_TOAST_SAVED")];
                                  [self.delegate sharerDidShareObject:self.objectToShare withInfo:self.info];
    }];
}

-(void)shareVideo
{
    [NSException raise:NSInvalidArgumentException
                format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
}

-(void)cancel
{
    [super cancel];
    [self.delegate sharerDidCancelWithInfo:self.info];
}



@end
