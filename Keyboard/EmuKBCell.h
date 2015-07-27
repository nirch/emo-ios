//
//  EmuKBCell.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLAnimatedImageView;

@interface EmuKBCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimGifView;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@property (nonatomic) NSURL *pendingAnimatedGifURL;
@property (nonatomic) NSURL *animatedGifURL;

-(void)showPendingGifURL;

@end
