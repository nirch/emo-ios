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
@property (weak, nonatomic) IBOutlet UISlider *guiWeightSlider;

@property (weak, nonatomic) IBOutlet UIView *guiContourBadContainer;
@property (weak, nonatomic) IBOutlet UIView *guiContourGoodContainer;

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
    self.guiWeightSlider.value = 0;
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
    
    CGRect fBad = self.badBGStartFrame;
    fBad.size.height *= (1-self.goodBackgroundWeight);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.guiContourBadContainer.frame = fBad;
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onWeightSliderValueChanged:(UISlider *)slider
{
    _goodBackgroundWeight = slider.value;
    [self update];
}


@end
