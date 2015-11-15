//
//  EmuCell.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuCell.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>
#import "EMCaches.h"

#define TAG @"EmuCell"

@interface EmuCell()



@end

@implementation EmuCell

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
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Load the data in the background and into virtual memory if possible.
        NSError *error;
        NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL options:NSDataReadingMappedIfSafe error:&error];
        if (error || animGifData == nil) {
            return;
        }
        
        FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
        __weak EmuCell *wSelf = self;
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

-(void)setAnimatedGifNamed:(NSString *)gifName
{
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:gifName withExtension:@"gif"];
    FLAnimatedImage *animGif = [EMCaches.sh.gifsDataCache objectForKey:gifURL];
    if (animGif == nil) {
        NSData *animGifData = [NSData dataWithContentsOfURL:gifURL];
        animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
        [EMCaches.sh.gifsDataCache setObject:animGif forKey:[gifURL description]];
    }
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

@end
