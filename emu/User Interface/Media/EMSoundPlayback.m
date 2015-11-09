//
//  EMSoundPlayback.m
//  emu
//
//  Created by Aviv Wolf on 07/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMSoundPlayback.h"

@interface EMSoundPlayback()

@end

@implementation EMSoundPlayback

@synthesize player = _player;
@synthesize currentItem = _currentItem;

-(void)setUpItem:(AFSoundItem *)item {
    
    self.player = [[AVPlayer alloc] initWithURL:item.URL];
    [self.player play];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    
    self.status = AFSoundStatusPlaying;
    
    _currentItem = item;
    self.currentItem.duration = (int)CMTimeGetSeconds(_player.currentItem.asset.duration);
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}


@end
