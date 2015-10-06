//
//  EMEmuCell.m
//  emu
//
//  Created by Aviv Wolf on 9/28/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmuCell.h"
#import "EMDB.h"
#import <FLAnimatedImage.h>

@interface EMEmuCell()

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimatedGif;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *guiFailedImage;
@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiSelectionIndicator;


@end

@implementation EMEmuCell

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                     } completion:nil];
    [self setNeedsDisplay];
}

-(void)updateStateWithEmu:(Emuticon *)emu forIndexPath:(NSIndexPath *)indexPath
{
    _label = [SF:@"%@ - %@", emu.emuDef.package.name, emu.emuDef.name];
}

-(void)updateGUI
{
    self.guiDebugLabel.text = self.label;
    self.guiSelectionIndicator.hidden = !self.selectable;
    self.guiSelectionIndicator.highlighted = self.selected;
    self.guiThumbImage.image = [UIImage imageNamed:@"kim"];
    
    
    CGAffineTransform selectionTransform = self.selectable && self.selected? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity;
    self.guiThumbImage.transform = selectionTransform;
}

@end
