//
//  EMFeaturedCell.m
//  emu
//
//  Created by Aviv Wolf on 9/27/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFeaturedCell.h"
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>
#import <FLAnimatedImage.h>
#import <FLAnimatedImageView.h>

@interface EMFeaturedCell()

@property (weak, nonatomic) IBOutlet UIButton *guiButton;
@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiPosterImage;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiPosterGif;

@end

@implementation EMFeaturedCell

-(void)updateGUI
{
    self.guiDebugLabel.text = self.debugLabel;
    self.guiDebugLabel.hidden = YES;
    [self updatePoster];
}

-(void)updatePoster
{
    self.guiPosterGif.animatedImage = nil;
    [self.guiPosterGif stopAnimating];

    self.guiPosterImage.image = nil;
    
    if ([self isPosterAnimatedGif]) {
        [self loadPosterAnimatedGif];
    } else {
        [self loadPosterImage];
    }
}

-(BOOL)isPosterAnimatedGif
{
    if ([self.posterURL.description.lowercaseString hasSuffix:@".gif"]) return YES;
    return NO;
}

-(void)loadPosterAnimatedGif
{
    [self.guiPosterGif pin_setImageFromURL:self.posterURL];
}

-(void)loadPosterImage
{
    [self.guiPosterImage pin_setImageFromURL:self.posterURL];
}


@end
