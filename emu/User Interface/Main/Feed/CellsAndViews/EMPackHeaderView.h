//
//  EMPackHeaderView.h
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMPackHeaderView : UICollectionReusableView

/**
 *  The label of the pack.
 */
@property (nonatomic) NSString *label;

/**
 *  The section index currently using this view.
 */
@property (nonatomic) NSInteger sectionIndex;

/**
 *  Is hd content available for this pack.
 */
@property (nonatomic) BOOL hdAvailable;
@property (nonatomic) BOOL hdProductValided;
@property (nonatomic) BOOL hdUnlocked;
@property (nonatomic) NSString *hdPriceLabel;

/**
 *  Update UI of the header according to current state.
 */
-(void)updateGUI;

@end
