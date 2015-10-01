//
//  EMUISound.m
//  emu
//
//  Created by Aviv Wolf on 2/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMUISound.h"

#import <AFSoundManager.h>

@interface EMUISound()

@property (nonatomic) NSDictionary *soundFiles;
@property (nonatomic) NSMutableDictionary *sounds;
@property (nonatomic) NSMutableDictionary *players;

@end

@implementation EMUISound

#pragma mark - Initialization
// A singleton
+(EMUISound *)sharedInstance
{
    static EMUISound *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMUISound alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMUISound *)sh
{
    return [EMUISound sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self loadAudioFiles];
    }
    return self;
}

-(void)loadAudioFiles
{
    // Map sound names to audio files in bundle.
    self.soundFiles = @{SND_HAPPY:@"goodBG.wav",
                        SND_PRESSED_BUTTON:@"pressedButton.wav",
                        SND_CANCEL:@"cancel.wav",
                        SND_START_RECORDING:@"startRecording.wav",
                        SND_RECORDING_ENDED:@"endRecording.wav",
                        SND_SOFT_CLICK:@"plasticClickSound.wav",
                        SND_SWIPE:@"simpleSwipe.wav",
                        SND_FOCUSING:@"focusing.wav",
                        SND_POP:@"pop.wav"
                        };
    
    // Load audio files from bundle.
    self.players = [NSMutableDictionary new];
    self.sounds = [NSMutableDictionary new];
    for (NSString *soundName in self.soundFiles.allKeys) {
        NSString *soundFile = self.soundFiles[soundName];
        AFSoundItem *soundItem = [[AFSoundItem alloc] initWithLocalResource:soundFile atPath:nil];
        self.sounds[soundName] = soundItem;
    }
}

#pragma mark - playing
-(void)playSoundNamed:(NSString *)soundName
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (![audioSession.category isEqualToString:AVAudioSessionCategoryAmbient]) {
        NSError *setCategoryErr = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&setCategoryErr];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }

    AFSoundPlayback *player;
    if (self.players[soundName]) {
        player = self.players[soundName];
        [player restart];
        [player play];
    } else {
        NSError *setCategoryErr = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&setCategoryErr];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        AFSoundItem *soundItem = self.sounds[soundName];
        player = [[AFSoundPlayback alloc] initWithItem:soundItem];
        self.players[soundName] = player;
    }
}

@end
