//
//  EMShareFBMessanger.h
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShare.h"

@interface EMShareFBMessanger : EMShare

#pragma mark - Application flow
-(void)onAppDidBecomeActive;
-(void)onFBMCancel;
-(void)onFBMReply;
-(void)onFBMOpen;

@end
