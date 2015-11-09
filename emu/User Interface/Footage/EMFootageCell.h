//
//  EMFootageCell.h
//  emu
//
//  Created by Aviv Wolf on 10/10/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserFootage;

@interface EMFootageCell : UICollectionViewCell

@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isHD;

-(void)updateStateWithFootage:(UserFootage *)footage;
-(void)updateGUI;

-(void)startPlayingFootage:(UserFootage *)footage;

@end
