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
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>
#import "emu-Swift.h"
#import "EMRenderTypes.h"

@interface EMEmuCell()


@property (weak, nonatomic) IBOutlet UIButton *guiBGButton;
@property (weak, nonatomic) IBOutlet UIButton *guiEmptyButton;

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimatedGif;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiDownloadingAnimatedGif;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiRenderingAnimatedGif;

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
    if (emu == nil) {
        [self updateStateToEmpty];
        return;
    }
    
    //_label = [SF:@"%@", emu.timeCreated];
    _label = @"";
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
        
        NSDictionary *info =@{
                              @"for":@"emu",
                              emkIndexPath:indexPath,
                              emkEmuticonOID:emu.oid,
                              emkPackageOID:emu.emuDef.package.oid,
                              @"inUI":self.inUI?self.inUI:@"unknown",
                              emkRenderType:@"shortLDPreview",
                              emkMediaType:hcrGIF
                              };
                
        [EMRenderManager3.sh enqueueEmu:emu
                             renderType:EMRenderTypeShortLowDefPreview
                              mediaType:EMMediaDataTypeGIF
                             fullRender:NO
                               userInfo:info
                               oldStyle:YES];
        
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

-(void)updateStateToEmpty
{
    _label = nil;
    _oid = nil;
    _state = EMEmuCellStateEmpty;
}

-(void)updateStateToPlaceHolder
{
    _label = nil;
    _oid = nil;
    _state = EMEmuCellStatePlaceHolderEmu;
}

-(void)updateGUI
{
    // Just for debugging.
    self.guiDebugLabel.text = self.label;

    // Selections.
    self.guiSelectionIndicator.hidden = !self.selectable;
    self.guiSelectionIndicator.highlighted = self.selected;

    if (self.state == EMEmuCellStateFailed) {
        [self updateGUIToFailedState];
    } else if (self.state == EMEmuCellStateRequiresResources) {
        [self updateGUIToRequiresResources];
    } else if (self.state == EMEmuCellStateSentForRendering) {
        [self updateGUIToSentForRendering];
    } else if (self.state == EMEmuCellStateReady) {
        [self updateGUIToReady];
    } else if (self.state == EMEmuCellStateEmpty) {
        [self updateGUIEmpty];
    } else if (self.state == EMEmuCellStatePlaceHolderEmu) {
        [self updateGUIPlaceHolder];
    } else {
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{@"msg":[SF:@"Unset state for cell!"]}];
    }
}

-(void)updateGUIEmpty
{
    [self clear];
    self.guiEmptyButton.hidden = NO;

    self.guiBGButton.hidden = YES;
    self.guiBGImage.hidden = YES;
}

-(void)updateGUIPlaceHolder
{
    [self clear];
    self.guiThumbImage.hidden = NO;
    self.guiThumbImage.image = [UIImage imageNamed:@"emuPlaceHolder"];
    self.guiThumbImage.alpha = 1;
}

-(void)updateGUIToFailedState
{
    [self clear];
    self.guiFailedImage.hidden = NO;
}

-(void)updateGUIToRequiresResources
{
    [self clear];
    self.guiDownloadingAnimatedGif.hidden = NO;
    [self.guiDownloadingAnimatedGif startAnimating];
}

-(void)updateGUIToSentForRendering
{
    [self clear];
    self.guiRenderingAnimatedGif.hidden = NO;
    [self.guiRenderingAnimatedGif startAnimating];
}

-(void)updateGUIToReady
{
    // Clear the animated gif.
    [self clear];

    // Capture the oid, so we can use it later in the async blocks below.
    NSString *oid = self.oid;
    
    // First load async the thumb nail image.
    // Wait a few moments after thumb image loads, before trying to load the animated gif.
    // Reason: we sometimes really don't need the overhead of loading big animated gifs from disk/cache
    // because the user just scrolls through lots of emus.
    __weak EMEmuCell *wSelf = self;
    
    wSelf.guiAnimatedGif.alpha = 0;
    [wSelf.guiAnimatedGif pin_cancelImageDownload];
    [wSelf.guiAnimatedGif setImage:nil];
    
    [self.guiThumbImage pin_cancelImageDownload];
    [self.guiThumbImage setImage:nil];
    self.guiThumbImage.alpha = 0.75;
    
    [self.guiThumbImage pin_setImageFromURL:[NSURL fileURLWithPath:self.thumbPath] completion:^(PINRemoteImageManagerResult *result) {

        if (![oid isEqualToString:wSelf.oid]) return;
        self.guiThumbImage.hidden = NO;

        dispatch_after(DTIME(0.8 + (arc4random() % 40 / 10.0)), dispatch_get_main_queue(), ^{
            // Ensure still related to the same emu.
            // If not, move along there is nothing to see here.
            if (![oid isEqualToString:wSelf.oid]) return;
            
            // Async load the anim gif.
            wSelf.guiAnimatedGif.alpha = 0;
            [wSelf.guiAnimatedGif pin_setImageFromURL:self.gifURL
                                           completion:^(PINRemoteImageManagerResult *result) {
                                               [UIView animateWithDuration:0.5 delay:0.0
                                                                   options:UIViewAnimationOptionAllowUserInteraction
                                                                animations:^{
                                                                    if (![oid isEqualToString:wSelf.oid]) return;
                                                                    wSelf.guiThumbImage.alpha = 0;
                                                                    wSelf.guiAnimatedGif.alpha = 1;
                                                                } completion:^(BOOL finished) {
                                                                    if (![oid isEqualToString:wSelf.oid]) return;
                                                                    wSelf.guiThumbImage.hidden = YES;
                                                                    wSelf.guiThumbImage.image = nil;
                                                                }];
                                           }];
        
        });
    }];
}

-(void)clear
{
    // Clear indicators
    self.guiFailedImage.hidden = YES;
    
    if (self.guiDownloadingAnimatedGif.animatedImage == nil) {
        [self loadAnimatedGifNamed:@"downloading"
               inAnimatedImageView:self.guiDownloadingAnimatedGif];
        self.guiDownloadingAnimatedGif.alpha = 0.2;
    }

    if (self.guiRenderingAnimatedGif.animatedImage == nil) {
        [self loadAnimatedGifNamed:@"rendering"
               inAnimatedImageView:self.guiRenderingAnimatedGif];
    }
    
    self.guiDownloadingAnimatedGif.hidden = YES;
    self.guiRenderingAnimatedGif.hidden = YES;
    
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
    
    // The background buttons and images
    self.guiBGImage.hidden = NO;
    self.guiBGButton.hidden = NO;
    self.guiEmptyButton.hidden = YES;
}

-(void)loadAnimatedGifNamed:(NSString *)gifName inAnimatedImageView:(FLAnimatedImageView *)imageView
{
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:gifName withExtension:@"gif"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    NSData *animGifData = [EMCaches.sh.gifsDataCache objectForKey:gifName];
    if (animGifData == nil) {
        animGifData = [NSData dataWithContentsOfURL:gifURL options:NSDataReadingMappedIfSafe error:nil];
        [EMCaches.sh.gifsDataCache setObject:animGifData forKey:gifName];
    }
    
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    imageView.animatedImage = animatedImage;
}

@end
