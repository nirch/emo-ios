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
    
    NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
    FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
    [self.guiAnimGifView startAnimating];
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

@end