//
//  EMFootageCell.m
//  emu
//
//  Created by Aviv Wolf on 10/10/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFootageCell.h"
#import "EMDB.h"
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>

@interface EMFootageCell()

@property (weak, nonatomic) IBOutlet UIView *guiContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *guiAnimatedImages;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimatedGif;
@property (weak, nonatomic) IBOutlet UIView *guiIsDefaultIndicator;
@property (weak, nonatomic) IBOutlet UILabel *guiHDIndicator;


@property (nonatomic) NSString *oid;
@property (nonatomic) NSURL *thumbURL;
@property (nonatomic) NSURL *gifURL;
@property (nonatomic) NSString *imagesPathPTN;

@end

@implementation EMFootageCell

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
    
    // Add some spring animation on clicked on cells.
    self.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [UIView animateWithDuration:0.8
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                     } completion:nil];
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initGUI];
}

-(void)initGUI
{
}


#pragma mark - State
-(void)resetState
{
    self.oid = nil;
    self.thumbURL = nil;
}

-(void)updateStateWithFootage:(UserFootage *)footage
{
    [self resetState];
    if (footage == nil) return;
    
    self.oid = footage.oid;
    if (footage.gifAvailable.boolValue && footage.pathToUserGif) {
        self.gifURL = [NSURL fileURLWithPath:footage.pathToUserGif];
        self.imagesPathPTN = nil;
    } else if (footage.pngSequenceAvailable.boolValue) {
        self.gifURL = nil;
         self.imagesPathPTN = [footage imagesPathPTN];   
    }
    self.thumbURL = [footage urlToThumbImage];

}

#pragma mark - UI
-(void)clearGUI
{
    self.guiContainer.backgroundColor = [UIColor clearColor];

    self.guiThumbImage.image = nil;
    [self.guiThumbImage stopAnimating];
    self.guiThumbImage.animationImages = nil;
    
    self.guiIsDefaultIndicator.hidden = YES;
    self.guiHDIndicator.hidden = YES;
    
    [self.guiAnimatedGif stopAnimating];
    self.guiAnimatedGif.image = nil;
    self.guiAnimatedGif.animatedImage = nil;
    
    CALayer *l = self.guiContainer.layer;
    UIImage *dottedPattern = [UIImage imageNamed:@"dashedBorder"];
    l.borderWidth = 1;
    l.borderColor = [UIColor colorWithPatternImage:dottedPattern].CGColor;

    l.shadowRadius = 0.0f;
    l.shadowOpacity = 0.0;
}

-(void)updateGUI
{
    [self clearGUI];
    
    // If an empty cell, nothing to do.
    if (self.oid == nil) return;
    
    if (self.isDefault) self.guiIsDefaultIndicator.hidden = NO;
    if (self.isHD) self.guiHDIndicator.hidden = NO;

    [self.guiThumbImage pin_setImageFromURL:self.thumbURL placeholderImage:[UIImage imageNamed:@"placeholderPositive480"]];    
}

-(void)startPlayingFootage:(UserFootage *)footage
{
    if (footage == nil || self.oid == nil) return;
    
    // Highlight border of the cell and add a shadow
    CALayer *l = self.guiContainer.layer;
    UIImage *dottedPattern = [UIImage imageNamed:@"dashedBorderSelected"];
    l.borderWidth = 3;
    l.borderColor = [UIColor colorWithPatternImage:dottedPattern].CGColor;
    
    l.shadowColor = [UIColor grayColor].CGColor;
    l.shadowRadius = 5.0f;
    l.shadowOpacity = 0.4;
    
    self.guiThumbImage.image = nil;
    
    if (self.gifURL) {
        // A gif is available. Play the animated gif.
        [self.guiAnimatedGif pin_setImageFromURL:self.gifURL placeholderImage:[UIImage imageNamed:@"placeholderPositive480"]];
        return;
    }
    
    // No gif available (most probably an old style footage with a PNG Sequence)
    // Load images in background thread
    NSString *path = [footage pathForUserImages];
    NSString *ptn = [footage imagesPathPTN];
    NSTimeInterval duration = [footage duration].doubleValue;
    if (duration < 1) duration = 1;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray *imagesArray = [UserFootage imagesSequenceWithMaxNumberOfFrames:36
                                                                            ptn:ptn
                                                                           path:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.guiThumbImage.animationImages = imagesArray;
            self.guiThumbImage.animationRepeatCount = 0;
            self.guiThumbImage.animationDuration = duration;
            [self.guiThumbImage startAnimating];
        });
    });
}

@end
