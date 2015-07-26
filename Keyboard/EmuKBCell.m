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
    
    dispatch_after(DTIME(0.5), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Don't load the data right away.
        // Wait half a second, and check if the url changed or not.
        if (![_animatedGifURL.description isEqualToString:animatedGifURL.description]) return;
        
        // Load the data in the background.
        NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
        FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
        __weak EmuKBCell *wSelf = self;
        wSelf.guiAnimGifView.hidden = NO;
        wSelf.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Make sure this cell is still representing the same emu
            if (![_animatedGifURL isEqual:animatedGifURL]) return;
            
            // Play the loaded animGif and reveal.
            wSelf.guiAnimGifView.animatedImage = animGif;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{
                    wSelf.guiThumbView.alpha = 0;
                }];
            });
        });
    });
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

@end
