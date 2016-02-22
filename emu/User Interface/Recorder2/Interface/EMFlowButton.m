//
//  EMFlowButton.m
//  emu
//
//  Created by Aviv Wolf on 2/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFlowButton.h"

@implementation EMFlowButton

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
    
    [self setTitleColor:[EmuStyle colorButtonText] forState:UIControlStateNormal];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    self.positive = YES;
}


-(void)setPositive:(BOOL)positive
{
    UIColor *bgColor;
    bgColor = positive? [EmuStyle colorButtonBGPositive] : [EmuStyle colorButtonBGNegative];
    [self setBackgroundImage:[EmuStyle imageWithColor:bgColor] forState:UIControlStateNormal];
}

-(void)setBGColor:(UIColor *)color
{
    [self setBackgroundImage:[EmuStyle imageWithColor:color] forState:UIControlStateNormal];
}



@end
