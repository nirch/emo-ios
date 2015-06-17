//
//  EMImageInspector.m
//  emu
//
//  Created by Aviv Wolf on 6/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMImageInspector.h"

@interface EMImageInspector() {
    CFDataRef pixelData;
    CGImageAlphaInfo alphaInfo;
}

@property (atomic, strong) UIImage *image;

@end

@implementation EMImageInspector

-(instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.image = image;
        [self initData];
    }
    return self;
}

-(void)initData
{
    alphaInfo = CGImageGetAlphaInfo(self.image.CGImage);
    pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.image.CGImage));
}

-(UIColor *)colorAtPointArr:(NSArray *)pointArr
{
    NSAssert(pointArr.count == 2, @"Point array should be [X,Y]");
    return [self colorAtPoint:CGPointMake([pointArr[0] floatValue], [pointArr[1] floatValue])];
}


-(UIColor *)colorAtPoint:(CGPoint)point
{
    const UInt8 *data = CFDataGetBytePtr(pixelData);
    int x = point.x;
    int y = point.y;
    int pixelInfo = ((self.image.size.width  * y) + x ) * 4; // 4 bytes per pixel
    
    // Only RGB (we don't care about alpha
    int pos=0;
    if (alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaFirst) pos++;
    UInt8 red   = data[pixelInfo + ++pos];
    UInt8 green = data[pixelInfo + ++pos];
    UInt8 blue  = data[pixelInfo + ++pos];
    
    return [UIColor colorWithRed:red/255.0f
                           green:green/255.0f
                            blue:blue/255.0f
                           alpha:1/255.0f];
}

-(void)dealloc
{
    CFRelease(pixelData);
}

@end
