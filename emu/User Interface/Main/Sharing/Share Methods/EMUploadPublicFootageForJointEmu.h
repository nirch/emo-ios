//
//  EMUploadPublicFootageForJointEmu.h
//  emu
//
//  Created by Aviv Wolf on 7/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShare.h"

@interface EMUploadPublicFootageForJointEmu : EMShare

@property (nonatomic) UserFootage *footage;
@property (nonatomic) Emuticon *emu;
@property (nonatomic) NSInteger slotIndex;
@property (nonatomic) BOOL finishedSuccessfully;
@property (nonatomic) BOOL finished;
@property (nonatomic) NSError *error;

-(void)cancel;
-(void)uploadBeforeSharing;
-(void)shareAfterUploaded;

@end
