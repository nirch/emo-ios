//
//  EMSettingsSectionCell.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMSettingsSectionCell.h"

@interface EMSettingsSectionCell()

@property (weak, nonatomic) IBOutlet UILabel *guiTitle;

@end

@implementation EMSettingsSectionCell

-(void)updateGUI
{
    NSDictionary *info = self.info;
    self.guiTitle.text = info[@"title"];
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = nil;
}

@end
