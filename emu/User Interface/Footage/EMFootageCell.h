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

-(void)updateStateWithFootage:(UserFootage *)footage;
-(void)updateGUI;

-(void)startPlayingFootage:(UserFootage *)footage;
-(void)stopPlayingFootageAndClean;

@end
