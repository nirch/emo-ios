//
//  EMTestsResources.m
//  emu
//
//  Created by Aviv Wolf on 6/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTestsResources.h"
@import UIKit;

@implementation EMTestsResources

+(UIImage *)imageNamed:(NSString *)imageName ofType:(NSString *)imageType
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [bundle pathForResource:imageName ofType:imageType];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

@end
