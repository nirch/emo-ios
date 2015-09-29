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


@end

@implementation EMEmuCell


-(void)updateStateWithEmu:(Emuticon *)emu forIndexPath:(NSIndexPath *)indexPath
{
    _label = emu.emuDef.name;
}

-(void)updateGUI
{
    self.guiDebugLabel.text = self.label;
}

@end
