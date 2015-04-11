//
//  EmuSectionReusableView.m
//  emu
//
//  Created by Aviv Wolf on 4/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuSectionReusableView.h"

@implementation EmuSectionReusableView

-(void)setLabelTitle:(NSString *)title
{
    self.guiLabel.text = [self transformStringToVertical:title];
}


-(NSString *)transformStringToVertical:(NSString *)originalString
{
    NSMutableString *mutableString = [NSMutableString stringWithString:originalString];
    NSRange stringRange = [mutableString rangeOfString:mutableString];
    
    for (int i = 1; i < stringRange.length*2; i+=2)
    {
        [mutableString insertString:@"\n" atIndex:i];
    }
    
    return mutableString;
}

@end
