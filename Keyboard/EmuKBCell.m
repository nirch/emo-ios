//
//  EmuKBCell.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuKBCell.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

#define TAG @"EmuKBCell"

@interface EmuKBCell()

@end

@implementation EmuKBCell

-(void)showPendingGifURL
{
    [self setAnimatedGifURL:self.pendingAnimatedGifURL];
    self.pendingAnimatedGifURL = nil;
}

-(void)setAnimatedGifURL:(NSURL *)animatedGifURL
{
    _animatedGifURL = animatedGifURL;
    
    if (animatedGifURL == nil) {
        [self.guiAnimGifView stopAnimating];
        self.guiAnimGifView.animatedImage = nil;
        return;
    }
    
    [self.guiAnimGifView stopAnimating];
    self.guiAnimGifView.animatedImage = nil;
//    NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
    // Load the data in the background and into virtual memory if possible.
    NSError *error;
    NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL options:NSDataReadingMappedIfSafe error:&error];
    if (error || animGifData == nil) {
        return;
    }

    
    // Create the animated gif image with the loaded data.
    FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
    self.guiAnimGifView.animatedImage = animGif;
    
    // And show it on screen.
    [UIView animateWithDuration:0.2 animations:^{
        self.guiThumbView.alpha = 0;
    }];
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

@end
