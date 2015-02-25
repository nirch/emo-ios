//
//  EMRenderManager.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class UserFootage;
@class EmuticonDef;

@interface EMRenderManager : NSObject

#pragma mark - Initialization
+(EMRenderManager *)sharedInstance;
+(EMRenderManager *)sh;

#pragma mark - Rendering
-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef;

@end
