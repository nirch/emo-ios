//
//  EMPackCell.m
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackCell.h"

#define CORNER_RADIUS 6.0f

@interface EMPackCell()

@property (weak, nonatomic) IBOutlet UIView *guiClippedImage;


@end

@implementation EMPackCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initGUI];
}

#pragma mark - Initializations
-(void)initGUI
{
    CALayer *layer;
    
    // The clipping container
    layer = self.guiClippedImage.layer;
    layer.cornerRadius = CORNER_RADIUS;
}

@end
