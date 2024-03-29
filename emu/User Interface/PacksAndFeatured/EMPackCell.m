//
//  EMPackCell.m
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackCell.h"
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>

#define CORNER_RADIUS 6.0f

@interface EMPackCell()

@property (weak, nonatomic) IBOutlet UIImageView *guiClippedImage;
@property (weak, nonatomic) IBOutlet UIButton *guiButton;
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiPlaceHolderLabel;

@end

@implementation EMPackCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initImageProcessor];
    [self initGUI];
}

#pragma mark - Initializations
-(void)initGUI
{
    CALayer *layer;
    
    // The clipping container
    layer = self.guiClippedImage.layer;
    layer.shouldRasterize = YES;
}

-(void)initImageProcessor
{

}

#pragma mark - Update the UI of the cell
-(void)updateGUI
{
    [self.guiIcon pin_cancelImageDownload];
    [self.guiClippedImage pin_cancelImageDownload];
    self.guiLabel.text = nil;
    self.guiClippedImage.image = nil;
    self.guiButton.tag = self.indexTag;
    self.guiLabel.textColor = [UIColor darkGrayColor];
    self.guiIcon.image = nil;
    self.guiPlaceHolderLabel.text = self.label;
    self.guiPlaceHolderLabel.hidden = YES;

    if (!self.isBanner) {
        
        // Not a banner.
        // Just text and an icon.
        self.guiLabel.text = self.label;
        self.guiIcon.image = [UIImage imageNamed:@"iconPlaceHolder"];
        [self.guiIcon pin_setImageFromURL:self.iconURL completion:^(PINRemoteImageManagerResult *result) {
            self.guiIcon.backgroundColor = [UIColor clearColor];
        }];
        
    } else {
        
        // Loading wide banners.
        self.guiPlaceHolderLabel.hidden = NO;
        if (self.bannerURL != nil) {
            [self.guiClippedImage pin_setImageFromURL:self.bannerURL
                                         processorKey:@"rounded"
                                            processor:^UIImage *(PINRemoteImageManagerResult *result, NSUInteger *cost) {
                                                
                                                CGSize targetSize = result.image.size;
                                                CGRect imageRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
                                                UIGraphicsBeginImageContext(imageRect.size);
                                                
                                                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:15.0];
                                                [bezierPath addClip];
                                                
                                                CGFloat sizeMultiplier = MAX(targetSize.width / result.image.size.width, targetSize.height / result.image.size.height);
                                                
                                                CGRect drawRect = CGRectMake(0, 0, result.image.size.width * sizeMultiplier, result.image.size.height * sizeMultiplier);
                                                if (CGRectGetMaxX(drawRect) > CGRectGetMaxX(imageRect)) {
                                                    drawRect.origin.x -= (CGRectGetMaxX(drawRect) - CGRectGetMaxX(imageRect)) / 2.0;
                                                }
                                                if (CGRectGetMaxY(drawRect) > CGRectGetMaxY(imageRect)) {
                                                    drawRect.origin.y -= (CGRectGetMaxY(drawRect) - CGRectGetMaxY(imageRect)) / 2.0;
                                                }
                                                [result.image drawInRect:drawRect];
                                                
                                                UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
                                                UIGraphicsEndImageContext();
                                                return processedImage;
                                                
                                            }];
        }
    }
    
}


@end
