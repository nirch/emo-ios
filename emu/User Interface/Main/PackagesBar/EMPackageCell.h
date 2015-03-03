//
//  EMPackageCell.h
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMPackageCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiIcon;

@property (nonatomic) BOOL isSelected;

@end
