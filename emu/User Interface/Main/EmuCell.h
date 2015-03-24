//
//  EmuCell.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLAnimatedImageView;

@interface EmuCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimGifView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIImageView *guiLock;

@property (weak, nonatomic) IBOutlet UIImageView *guiFailedImage;
@property (weak, nonatomic) IBOutlet UILabel *guiFailedLabel;


@property (nonatomic) NSURL *animatedGifURL;

@end
