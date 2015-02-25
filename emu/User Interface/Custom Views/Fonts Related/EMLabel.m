//
//  EMLabel.m
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMLabel.h"

@implementation EMLabel

-(void)awakeFromNib
{
    [self initCustomFont];
}

-(void)initCustomFont
{
    CGFloat fontSize = self.font.pointSize;
    NSString *fontName = [EmuStyle.sh fontNameForStyle:self.styleFont];
    
    UIFont *customFont = [UIFont fontWithName:fontName size:fontSize];
    [self setFont:customFont];
}

-(void)setStyleColor:(NSString *)styleColor
{
    UIColor *color = [EmuStyle.sh styleColorNamed:styleColor];
    if (color) {
        [self setTextColor:color];
    }
}


@end
