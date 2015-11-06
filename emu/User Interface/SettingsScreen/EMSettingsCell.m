//
//  EMSettingsCell.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMSettingsCell.h"

@interface EMSettingsCell()

@property (weak, nonatomic) IBOutlet UILabel *guiTitle1;
@property (weak, nonatomic) IBOutlet UILabel *guiTitle2;
@property (weak, nonatomic) IBOutlet UILabel *guiTitle3;
@property (weak, nonatomic) IBOutlet UIButton *guiActionButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UISwitch *guiSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@end

@implementation EMSettingsCell

-(void)clear
{
    [self.guiActivity stopAnimating];
    self.guiIcon.image = [UIImage imageNamed:@"iconPlaceHolder"];
    self.guiTitle1.text = @"";
    self.guiTitle2.text = @"";
    self.guiTitle3.text = @"";
    self.guiLabel.text = @"";
}

-(void)updateGUI
{
    [self clear];
    
    [self.guiActionButton setTitle:@"" forState:UIControlStateNormal];
    if (self.itemInfo[@"title1"]) self.guiTitle1.text = self.itemInfo[@"title1"];
    if (self.itemInfo[@"title2"]) self.guiTitle2.text = self.itemInfo[@"title2"];
    if (self.itemInfo[@"title3"]) self.guiTitle3.text = self.itemInfo[@"title3"];
    if (self.itemInfo[@"actionText"]) self.guiLabel.text = self.itemInfo[@"actionText"];

    if (self.itemInfo[@"icon"]) self.guiIcon.image = [UIImage imageNamed:self.itemInfo[@"icon"]];
        
    if (self.itemInfo[@"boolSettingName"]) {
        self.guiSwitch.hidden = NO;
    } else {
        self.guiSwitch.hidden = YES;
    }
    
    if ([self.itemInfo[@"async"] boolValue]) {
        self.guiActivity.alpha = 1.0;
    } else {
        self.guiActivity.alpha = 0.0;
    }
}

-(void)startActivity
{
    [self.guiActivity startAnimating];
}

-(void)stopActivity
{
    [self.guiActivity stopAnimating];
}

@end
