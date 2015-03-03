//
//  EMPackageCell.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackageCell.h"
#import "EmuStyle.h"

@implementation EMPackageCell

-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    self.backgroundColor = isSelected? [EmuStyle colorButtonBGPositive] : [UIColor clearColor];
    self.guiLabel.textColor = isSelected? [EmuStyle colorText1] : [EmuStyle colorText2];
    
}

@end
