//
//  EMUISound.h
//  emu
//
//  Created by Aviv Wolf on 2/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define SND_HAPPY           @"happy"
#define SND_START_RECORDING @"start recording"
#define SND_PRESSED_BUTTON  @"pressed button"
#define SND_CANCEL          @"cancel"


@interface EMUISound : NSObject

#pragma mark - Initialization
+(EMUISound *)sharedInstance;
+(EMUISound *)sh;

#pragma mark - playing
-(void)playSoundNamed:(NSString *)soundName;

@end
