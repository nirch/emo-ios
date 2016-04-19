//
//  EMMajorRetakeOptionsSheet.h
//  emu
//
//  Created by Aviv Wolf on 10/9/15.
//  Copyright © 2015 Homage. All rights reserved.
//


#define EMK_EMU_FOOTAGE_ACTION_RETAKE @"emu footage action: retake"
#define EMK_EMU_FOOTAGE_ACTION_CHOOSE @"emu footage action: choose footage"

#import "EMHolySheet.h"

@interface EMEmuOptionsSheet : EMHolySheet

-(id)initWithEmuOID:(NSString *)emuOID;
-(void)configureActions;

@property (nonatomic, readonly) NSString *currentEmuOID;

@end
