//
//  Emuticon+JointEmuLogic.h
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Emuticon.h"

@interface Emuticon (JointEmuLogic)

-(NSInteger)jointEmuInvitationsSentCount;
-(NSString *)jointEmuOID;
-(NSString *)jointEmuInviteCodeAtSlot:(NSInteger)slot;

#pragma mark - AWS S3
-(NSString *)s3KeyForFile:(NSString *)fileName slot:(NSInteger)slot ext:(NSString *)ext;

@end
