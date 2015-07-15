//
//  EMUploadAndShare.h
//  emu
//
//  Created by Aviv Wolf on 7/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShare.h"

@interface EMUploadAndShare : EMShare

@property NSString *sharedLink;

-(void)uploadBeforeSharing;
-(void)shareAfterUploaded;

@end
