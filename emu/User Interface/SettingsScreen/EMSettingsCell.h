//
//  EMSettingsCell.h
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMSettingsCell : UITableViewCell

@property (nonatomic) NSString *cellType;
@property (nonatomic) NSDictionary *itemInfo;
@property (nonatomic) NSIndexPath *indexPath;

-(void)updateGUI;
-(void)startActivity;
-(void)stopActivity;


@end
