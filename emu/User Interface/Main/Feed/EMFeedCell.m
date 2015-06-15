//
//  EMFeedCell.m
//  emu
//
//  Created by Aviv Wolf on 6/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFeedCell.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>
#import "EMDB.h"
#import "AppManagement.h"
#import "EMRenderManager.h"

static NSData *loadingGifData;
@interface EMFeedCell()

@property (weak, nonatomic) IBOutlet UIImageView *guiCellBG;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimatedGif;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIImageView *guiLock;
@property (weak, nonatomic) IBOutlet UIImageView *guiEmuFailedIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiEmuFailedLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiDebugLabel;


@end

@implementation EMFeedCell

-(void)updateCellForEmu:(Emuticon *)emu info:(NSDictionary *)info
{
    if (emu.wasRendered.boolValue) {
        // Emu already rendered.
        [self.guiActivity stopAnimating];
        self.guiAnimatedGif.animatedImage = [FLAnimatedImage animatedImageWithGIFData:[emu animatedGifData]];
        self.guiAnimatedGif.hidden = NO;
    } else {
        // Emu not rendered yet. Still waiting.
        [self.guiAnimatedGif stopAnimating];
        self.guiAnimatedGif.hidden = YES;
        [self.guiActivity startAnimating];
        [EMRenderManager.sh enqueueEmuOID:emu.oid withInfo:info];
    }
    
    //
    // Extra info for debugging
    //
    if (AppManagement.sh.isTestApp) {
        [self _updateCellDebugInfoForEmu:(Emuticon *)emu info:(NSDictionary *)info];
    } else {
        self.guiDebugLabel.hidden = YES;
    }
}

-(NSData *)loadingAnimGifData
{
    if (loadingGifData != nil) return loadingGifData;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"dl" withExtension:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfURL:url];
    loadingGifData = gifData;
    return gifData;
}

#pragma mark - Debugging
-(void)_updateCellDebugInfoForEmu:(Emuticon *)emu info:(NSDictionary *)info
{
    self.guiDebugLabel.text = [SF:@"%@ %@", emu.emuDef.package.name, emu.emuDef.name];
}

@end
