//
//  EMBGFeedBackViewController.m
//  emo
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMBGFeedBackVC.h"

@interface EMBGFeedBackVC ()

@property (weak, nonatomic) IBOutlet UIProgressView *guiWeightIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *guiContourGood;
@property (weak, nonatomic) IBOutlet UIImageView *guiContourBad;
@property (weak, nonatomic) IBOutlet UIView *guiContourBadContainer;

@property (nonatomic) CGRect badBGStartFrame;

@end

@implementation EMBGFeedBackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self storeLayoutInfo];
}

#pragma mark - initializations
-(void)initGUI
{
    self.guiWeightIndicator.progress = 0;
    self.guiWeightIndicator.hidden = YES; // Used for debug
}

-(void)storeLayoutInfo
{
    self.badBGStartFrame = self.guiContourBadContainer.frame;
}

#pragma mark - User feedback
-(void)setGoodBackgroundWeight:(CGFloat)goodBackgroundWeight
{
    _goodBackgroundWeight = goodBackgroundWeight;
    [self update];
}

-(void)update
{
    self.guiWeightIndicator.progress = self.goodBackgroundWeight;
    
    CGRect f = self.badBGStartFrame;
    f.size.height *= (1-self.goodBackgroundWeight);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.guiContourBadContainer.frame = f;
    }];
}

@end
