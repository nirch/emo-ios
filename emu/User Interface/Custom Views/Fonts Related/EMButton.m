//
//  EMButton.m
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMButton.h"

@implementation EMButton

-(void)awakeFromNib
{
    [self initCustomFont];
}

-(void)initCustomFont
{
    // Font
    CGFloat fontSize = self.titleLabel.font.pointSize;
    NSString *fontName = [EmuStyle.sh fontNameForStyle:self.styleFont];
    UIFont *customFont = [UIFont fontWithName:fontName size:fontSize];
    [self.titleLabel setFont:customFont];    
}


-(void)setStyleColor:(NSString *)styleColor
{
    UIColor *color = [EmuStyle.sh styleColorNamed:styleColor];
    if (color) {
        [self setTitleColor:color forState:UIControlStateNormal];
    }
}



//-(void)debugListFontNames
//{
//    for (NSString* family in [UIFont familyNames])
//    {
//        NSLog(@"%@", family);
//        
//        for (NSString* name in [UIFont fontNamesForFamilyName: family])
//        {
//            NSLog(@"  %@", name);
//        }
//    }
//}

@end
