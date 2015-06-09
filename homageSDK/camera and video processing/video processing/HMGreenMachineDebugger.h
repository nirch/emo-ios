//
//  HMGreenMachineDebugger.h
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HMImageTools.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "ImageType/ImageTool.h"

@interface HMGreenMachineDebugger : NSObject

@property (weak, atomic) dispatch_queue_t outputQueue;

-(void)originalImage:(image_type *)m_original_image;
-(void)finishupWithInfo:(NSDictionary *)info;

@end
