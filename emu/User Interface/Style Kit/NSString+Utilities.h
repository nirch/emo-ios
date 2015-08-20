//
//  NSString+Utilities.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

// TODO:put this file in proper place. It shouldn't be in style kit.

///
/**
*  Parses a string representing a color in hex format and returns a UIColor
*
*  @param hexString The string representing a color in the format #RRGGBBAA (The alpha is optional. When absent FF is asumed)
*
*  @return A UIColor object.
*/
-(UIColor *)colorFromRGBAHexString;

///
/**
*  Trims white space from the beginning and end of the string.
*
*  @return A trimmed NSString.
*/
-(NSString *)stringWithATrim;

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end
