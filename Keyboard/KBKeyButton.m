//
//  KBKeyButton.m
//  emu
//
//  Created by Aviv Wolf on 4/6/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "KBKeyButton.h"
#import "EmuStyle.h"

@interface KBKeyButton()

@property (nonatomic) UIColor *normalStateBG;

@end

@implementation KBKeyButton

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initStyle];
    [self initTouches];
}

-(void)initStyle
{
    self.backgroundColor = [self normalStateBG];

    [self setTitleColor:[EmuStyle colorKBKeyText] forState:UIControlStateNormal];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [EmuStyle colorKBKeyBG].CGColor;
    self.layer.cornerRadius = 1;

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.layer.bounds].CGPath;
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0;
    
    
}

-(void)initTouches
{
    [self addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
}

-(void)setStrongKey:(BOOL)strongKey
{
    _normalStateBG = strongKey? [EmuStyle colorKBKeyStrongBG] : [EmuStyle colorKBKeyBG];
}

-(UIColor *)normalStateBG
{
    if (_normalStateBG) return _normalStateBG;
    _normalStateBG = self.strongKey? [EmuStyle colorKBKeyStrongBG] : [EmuStyle colorKBKeyBG];
    return _normalStateBG;
}

#pragma mark - UI States
-(void)released
{
    self.transform = CGAffineTransformIdentity;
    self.layer.borderColor = [self normalStateBG].CGColor;
    self.layer.shadowOpacity = 0;
    self.layer.zPosition = 0;
}

#pragma mark - Presses
// Scale up on button press
-(void)buttonPress:(UIButton*)button {
    if (!self.unmovingKey) {
        CGAffineTransform t = CGAffineTransformMakeScale(1.2, 1.2);
        t = CGAffineTransformTranslate(t, 0, - button.bounds.size.height * 0.25);
        button.transform = t;
    }
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.zPosition = 10;
    self.layer.shadowOpacity = 0.5;
}

// Scale down on button release
-(void)buttonRelease:(UIButton*)button {
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
        self.layer.borderColor = [self normalStateBG].CGColor;
        self.layer.shadowOpacity = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.layer.zPosition = 0;
        }
    }];
}

@end
