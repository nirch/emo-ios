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
#import "HMPanel.h"
#import "EMCaches.h"
#import "EMRenderManager2.h"
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>

@interface EMEmuCell()

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimatedGif;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *guiFailedImage;
@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiSelectionIndicator;

@property (nonatomic) NSString *thumbPath;
@property (nonatomic) NSURL *gifURL;

@end

@implementation EMEmuCell

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];

    if (self.selectable) {
        // For quicker selections,
        // no click animations on selectable cells.
        return;
    }
    
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

-(void)updateStateWithEmu:(Emuticon *)emu forIndexPath:(NSIndexPath *)indexPath
{
    _label = [SF:@"%@ - %@", emu.emuDef.package.name, emu.emuDef.name];
    _oid = emu.oid;
    
    // Determine cell state by emu object state
    if (emu.wasRendered.boolValue) {
        
        // ----------------------------------------------------------------
        // ALREADY RENDERED
        //
        // Emu already rendered. Just display it.
        // (Display thumb first and load animated gif in background thread)
        //
        self.gifURL = [emu animatedGifURL];
        self.thumbPath = [emu thumbPath];
        _state = EMEmuCellStateReady;
        
    } else if ([emu.emuDef allResourcesAvailable]) {
        
        // ----------------------------------------------------------------
        // RENDERING
        //
        // Emu not rendered yet, but all resources available.
        // We can render this emu.
        //
        UserFootage *mostPrefferedFootage = [emu mostPrefferedUserFootage];
        if (mostPrefferedFootage == nil) {
            [self updateStateToFailed];
            return;
        }
        [EMRenderManager2.sh enqueueEmu:emu indexPath:nil userInfo:@{
                                                                     @"for":@"emu",
                                                                     @"indexPath":indexPath,
                                                                     @"emuticonOID":emu.oid,
                                                                     @"packageOID":emu.emuDef.package.oid,
                                                                     @"inUI":self.inUI
                                                                     }];
        _state = EMEmuCellStateSentForRendering;
        
    } else {
        
        // ----------------------------------------------------------------
        // DOWNLOADING
        //
        _state = EMEmuCellStateRequiresResources;
    }

}

-(void)updateStateToFailed
{
    _state = EMEmuCellStateFailed;
}

-(void)updateGUI
{
    // Just for debugging.
    self.guiDebugLabel.text = self.label;

    // Selections.
    self.guiSelectionIndicator.hidden = !self.selectable;
    self.guiSelectionIndicator.highlighted = self.selected;
    CGAffineTransform selectionTransform = self.selectable && self.selected? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity;
    self.guiThumbImage.transform = selectionTransform;

    if (self.state == EMEmuCellStateFailed) {
        [self updateGUIToFailedState];
    } else if (self.state == EMEmuCellStateRequiresResources) {
        [self updateGUIToRequiresResources];
    } else if (self.state == EMEmuCellStateSentForRendering) {
        [self updateGUIToSentForRendering];
    } else if (self.state == EMEmuCellStateReady) {
        [self updateGUIToReady];
    } else {
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{@"msg":[SF:@"Unset state for cell!"]}];
    }
}

-(void)updateGUIToFailedState
{
    [self clear];
}

-(void)updateGUIToRequiresResources
{
    [self clear];
    self.guiAnimatedGif.alpha = 0.3;
    [self loadAnimatedGifNamed:@"downloading"];
}

-(void)updateGUIToSentForRendering
{
    [self clear];
    [self loadAnimatedGifNamed:@"rendering"];
}

-(void)updateGUIToReady
{
    // Clear the animated gif.
    [self clear];

    NSString *oid = self.oid;
    
    __weak EMEmuCell *wSelf = self;
    [self.guiThumbImage pin_setImageFromURL:[NSURL fileURLWithPath:self.thumbPath] completion:^(PINRemoteImageManagerResult *result) {
        if (![oid isEqualToString:wSelf.oid]) return;
        self.guiThumbImage.hidden = NO;
        dispatch_after(DTIME(0.7), dispatch_get_main_queue(), ^{
            if (![oid isEqualToString:wSelf.oid]) return;
            // Ensure still related to the same emu,
            // before loading the animated gif.
            [wSelf.guiAnimatedGif pin_setImageFromURL:self.gifURL
                                           completion:^(PINRemoteImageManagerResult *result) {
                                               wSelf.guiThumbImage.hidden = YES;
                                           }];
        });
    }];
}

-(void)clear
{
    // Clear animated gif
    [self.guiAnimatedGif stopAnimating];
    self.guiAnimatedGif.animatedImage = nil;
    self.guiAnimatedGif.alpha = 1.0;
    
    // Clear thumb.
    self.guiThumbImage.image = nil;
    self.guiThumbImage.hidden = YES;
    self.guiThumbImage.backgroundColor = [UIColor clearColor];
    
    // Cancel in progress loads
    [self.guiAnimatedGif pin_cancelImageDownload];
    [self.guiThumbImage pin_cancelImageDownload];
    
}

-(void)loadAnimatedGifNamed:(NSString *)gifName
{
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:gifName withExtension:@"gif"];
    self.guiAnimatedGif.contentMode = UIViewContentModeScaleAspectFit;
    [self.guiAnimatedGif pin_setImageFromURL:gifURL];
}

@end
