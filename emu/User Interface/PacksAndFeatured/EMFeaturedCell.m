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
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;

@property (nonatomic) BOOL alreadyInitialized;

@end

@implementation EMFeaturedCell

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
    
    // Add some spring animation on clicked on cells.
    self.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                     } completion:nil];
}



-(void)updateGUI
{
    if (!self.alreadyInitialized) {
        [self.guiPosterOverlay addMotionEffectWithAmount:17.0f];
        self.alreadyInitialized = YES;
    }
    
    self.guiDebugLabel.text = self.debugLabel;
    self.guiDebugLabel.hidden = YES;
    [self updatePoster];
}

-(void)updatePoster
{
    // Clear all.
    [self.guiPosterGif pin_cancelImageDownload];
    [self.guiPosterImage pin_cancelImageDownload];
    [self.guiPosterOverlay pin_cancelImageDownload];
    [self.guiPosterGif stopAnimating];
    self.guiPosterGif.animatedImage = nil;
    self.guiPosterImage.image = nil;
    self.guiPosterOverlay.image = nil;
    self.guiLabel.text = self.label;
    self.guiLabel.alpha = 1.0;

    
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
    self.guiLabel.alpha = 0;
    self.guiPosterOverlay.alpha = 0;
    NSString *localThumbName = [self.animatedPosterThumbURL lastPathComponent];
    [self.guiPosterImage pin_setImageFromURL:self.animatedPosterThumbURL
                            placeholderImage:[UIImage imageNamed:localThumbName]
                                  completion:^(PINRemoteImageManagerResult *result) {
                                      // Load the big animated gif poster
                                      [self.guiPosterGif pin_setImageFromURL:self.posterURL completion:^(PINRemoteImageManagerResult *result) {
                                          if (result.error == nil) {
                                              self.guiPosterOverlay.alpha = 1;   
                                          }
                                      }];
    }];
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
