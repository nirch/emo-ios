//
//  HMImageTools.h
//  emo
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "Gpw/Vtool/Vtool.h"
#import "MattingLib/UniformBackground/UniformBackground.h"

@interface HMImageTools : NSObject

+(void)saveImageType3:(image_type *)image3 withName:(NSString *)name;
+(void)saveImage:(UIImage *)image withName:(NSString *)name;

@end
