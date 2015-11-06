//
//  EMSettingsSectionCell.h
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMSettingsSectionCell : UITableViewCell

@property (nonatomic) NSDictionary *info;
-(void)updateGUI;

@end
