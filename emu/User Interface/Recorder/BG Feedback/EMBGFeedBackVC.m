//
//  EMBGFeedBackViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMBGFeedBackVC.h"
#import "EMSilhouetteView.h"
#import "AWFanOpeningView.h"

@interface EMBGFeedBackVC ()

@property (weak, nonatomic) IBOutlet UIProgressView *guiWeightIndicator;
@property (weak, nonatomic) IBOutlet UISlider *guiWeightSlider;

@property (weak, nonatomic) IBOutlet AWFanOpeningView *guiContourBadContainer;
@property (weak, nonatomic) IBOutlet AWFanOpeningView *guiContourGoodContainer;

@property (weak, nonatomic) IBOutlet EMSilhouetteView *guiSilhouetteBG;

@property (nonatomic) CGRect badBGStartFrame;

@end

@implementation EMBGFeedBackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupEffects];
    [self storeLayoutInfo];
    [self update];
}

#pragma mark - initializations
-(void)initGUI
{
    self.guiWeightIndicator.progress = 0;
    self.guiWeightSlider.value = 0;
    self.guiWeightIndicator.hidden = YES; // Used for debug
}


-(void)setupEffects
{
    [self.guiSilhouetteBG setupEffects];
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
    
    CGFloat p1 = 1-self.goodBackgroundWeight;
    
    self.guiContourGoodContainer.startAngle = 180*p1 - 180;
    self.guiContourGoodContainer.endAngle = -180*p1 + 180;
    [self.guiContourGoodContainer updateSlice];

    self.guiContourBadContainer.startAngle = 180*p1 - 180;
    self.guiContourBadContainer.endAngle = -180*p1 + 180 - 360;
    [self.guiContourBadContainer updateSlice];
}

#pragma mark - Show/Hide
-(void)showAnimated:(BOOL)animated
{
    self.view.hidden = NO;

    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showAnimated:NO];
        }];
        return;
    }

    self.view.alpha = 1;
    self.view.transform = CGAffineTransformIdentity;
}

-(void)hideAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self hideAnimated:NO];
                         } completion:^(BOOL finished) {
                             self.view.hidden = YES;
                         }];
        return;
    }

    CGAffineTransform t = CGAffineTransformMakeScale(3.5, 3.5);
    t = CGAffineTransformTranslate(t, 0, -self.view.bounds.size.height/3.0);
    self.view.transform = t;
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
