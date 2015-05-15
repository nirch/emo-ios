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

    FLAnimatedImage *animGif = [EMCaches.sh.gifsDataCache objectForKey:[animatedGifURL description]];
    if (animGif == nil) {
        // If not cached, load it from url.
        NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
        animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];

        // Temp solution: Don't put it in the cache automatically (prefetch from somewhere else for now).
        // TODO: finish implementation.
        //[EMCaches.sh.gifsDataCache setObject:animGif forKey:[animatedGifURL description]];
    } else {
        // We have a cached animated gif.
        // HMLOG(TAG, EM_DBG, @"Used cached animated gif");
    }
    
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
    //[self.guiAnimGifView startAnimating];
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

@end
