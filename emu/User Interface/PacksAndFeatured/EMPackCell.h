//
//  EMPackCell.h
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMPackCell : UICollectionViewCell

/**
 *  The text that will be used on the label of the pack cell.
 */
@property (nonatomic) NSString *label;
@property (nonatomic) NSURL *bannerURL;
@property (nonatomic) NSURL *iconURL;
@property (nonatomic) NSInteger indexTag;
@property (nonatomic) BOOL isBanner;


-(void)updateGUI;

@end
