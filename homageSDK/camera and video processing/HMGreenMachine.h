//
//  HMGreenMachine.h
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMVideoProcessingProtocol.h"
#import <AVFoundation/AVFoundation.h>

@interface HMGreenMachine : NSObject<
    HMVideoProcessingProtocol
>

+(HMGreenMachine *)greenMachineWithBGImage:(UIImage *)backgroundImage
                           contourFileName:(NSString *)contourFileName;


@end
