//
//  EMBuyButton.m
//  emu
//
//  Created by Aviv Wolf on 17/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMBuyButton.h"
#import "EmuStyle.h"

@implementation EMBuyButton

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(void)initGUI
{
    self.backgroundColor = [UIColor whiteColor];
    [self setTitleColor:[EmuStyle colorMain1] forState:UIControlStateNormal];
    
    CALayer *l = self.layer;
    l.borderColor = [EmuStyle colorMain1].CGColor;
    l.borderWidth = 2;
}

@end
