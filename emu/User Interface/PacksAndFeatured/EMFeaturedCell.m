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
#import "UIView+MotionEffect.h"

@interface EMFeaturedCell()

@property (weak, nonatomic) IBOutlet UIButton *guiButton;
@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiPosterImage;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiPosterGif;
@property (weak, nonatomic) IBOutlet UIImageView *guiPosterOverlay;

@property (nonatomic) BOOL alreadyInitialized;

@end

@implementation EMFeaturedCell

-(void)updateGUI
{
    if (!self.alreadyInitialized) {
        [self.guiPosterOverlay addMotionEffectWithAmount:10.0f];
        self.alreadyInitialized = YES;
    }
    
    self.guiDebugLabel.text = self.debugLabel;
    self.guiDebugLabel.hidden = YES;
    [self updatePoster];
}

-(void)updatePoster
{
    // Clear all.
    self.guiPosterGif.animatedImage = nil;
    [self.guiPosterGif stopAnimating];
    self.guiPosterImage.image = nil;
    self.guiPosterOverlay.image = nil;
    
    // Display the image or animated gif
    if ([self isPosterAnimatedGif]) {
        [self loadPosterAnimatedGif];
    } else {
        [self loadPosterImage];
    }
    
    // If required, also show the overlay.
    if (self.posterOverlayURL) {
        [self loadPosterOverlay];
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

-(void)loadPosterOverlay
{
    [self.guiPosterOverlay pin_setImageFromURL:self.posterOverlayURL];
}


@end
