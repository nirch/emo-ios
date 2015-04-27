//
//  EmuStyle.h
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuBaseStyle.h"

@interface EmuStyle : EmuBaseStyle

#pragma mark - Initialization
+(EmuStyle *)sharedInstance;
+(EmuStyle *)sh;

#pragma mark - Fonts
-(NSString *)fontNameForStyle:(NSString *)style;
-(UIFont *)fontForStyle:(NSString *)style sized:(NSInteger)size;

#pragma mark - Colors
+(UIImage *)imageWithColor:(UIColor *)color;
-(UIColor *)styleColorNamed:(NSString *)colorName;


@end
