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


@property (nonatomic) NSString *oid;
@property (nonatomic) NSURL *thumbURL;
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
    self.thumbURL = [footage urlToThumbImage];
    self.imagesPathPTN = [footage imagesPathPTN];
}

#pragma mark - UI
-(void)clearGUI
{
    self.guiContainer.backgroundColor = [UIColor clearColor];
    self.guiThumbImage.image = nil;
    [self.guiThumbImage stopAnimating];
    self.guiThumbImage.animationImages = nil;
    
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
    
    self.guiContainer.backgroundColor = [UIColor whiteColor];
    
    [self.guiThumbImage pin_setImageFromURL:self.thumbURL];
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
