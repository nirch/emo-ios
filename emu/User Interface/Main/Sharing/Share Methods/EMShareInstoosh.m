//
//  EMShareMail.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import AssetsLibrary;

#import "EMShareInstoosh.h"
#import <Toast/UIView+Toast.h>
#import "NSString+Utilities.h"

@interface EMShareInstoosh()

@end

@implementation EMShareInstoosh

-(void)share
{
    [super share];
    [self shareSelection];
}

-(void)shareVideo
{
    [super shareVideo];
    
    // Info about the shared video
    Emuticon *emu = self.objectToShare;
    NSURL *videoLocalURL = [emu videoURL];
    NSString *caption = self.userInputText?self.userInputText:@"";
    
    // Write the video to the library and share to instagram.
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoLocalURL completionBlock:^(NSURL *assetURL, NSError *error) {

        // Build instagram deep link to the video asset
        NSString *escapedURLString = [[assetURL absoluteString] urlEncodeUsingEncoding:NSUTF8StringEncoding];
        NSString *escapedCaptionString = [caption urlEncodeUsingEncoding:NSUTF8StringEncoding];
        NSString *instagramURLString =[NSString stringWithFormat:@"instagram://library?AssetPath=%@&InstagramCaption=%@",
                                       escapedURLString,
                                       escapedCaptionString];
        NSURL *instagramURL = [NSURL URLWithString:instagramURLString];
        
        // Open the deep link
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [[UIApplication sharedApplication] openURL:instagramURL];
        }
    }];
}

@end
