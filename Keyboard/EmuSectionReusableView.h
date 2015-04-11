//
//  EmuSectionReusableView.h
//  emu
//
//  Created by Aviv Wolf on 4/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmuSectionReusableView : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UIView *guiContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;

-(void)setLabelTitle:(NSString *)title;

@end
