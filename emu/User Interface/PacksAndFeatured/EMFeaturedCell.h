//
//  EMFeaturedCell.h
//  emu
//
//  Created by Aviv Wolf on 9/27/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMFeaturedCell : UICollectionViewCell

@property (nonatomic) NSURL *posterURL;
@property (nonatomic) NSURL *animatedPosterThumbURL;
@property (nonatomic) NSURL *posterOverlayURL;
@property (nonatomic) NSString *debugLabel;
@property (nonatomic, readonly) BOOL isPosterAnimatedGif;
@property (nonatomic) NSString *label;
@property (nonatomic) NSString *name;

/**
 *  Update the UI of the cell according to current set properties.
 */
-(void)updateGUI;

@end
