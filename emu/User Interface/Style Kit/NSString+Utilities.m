//
//  NSString+Utilities.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

-(UIColor *)colorFromRGBAHexString
{
    float red = 0.5;
    float green = 0.5;
    float blue = 0.5;
    float alpha = 0.5;
    
    NSString *cleanString = [self stringByReplacingOccurrencesOfString:@"#" withString:@""];
    cleanString = [cleanString stringWithATrim];
    if (cleanString.length==6)
        cleanString = [cleanString stringByAppendingString:@"FF"];
    
    // Parse the string to rgba values
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    red = ((baseValue >> 24) & 0xFF)/255.0f;
    green = ((baseValue >> 16) & 0xFF)/255.0f;
    blue = ((baseValue >> 8) & 0xFF)/255.0f;
    alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    return color;
}

-(NSString *)stringWithATrim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]%\n ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding)));
}


@end
