//
//  ViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "RecorderViewController.h"

@interface RecorderViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiUserControls1Container;
@property (weak, nonatomic) IBOutlet UIView *guiUserControls2Container;

@end

@implementation RecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUI];
}

-(void)initGUI
{
    CALayer *layer = self.guiUserControls1Container.layer;
    layer.shadowOffset = CGSizeMake(0, 10);
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.3;
    layer.shadowRadius = 15;
    layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;

    layer = self.guiUserControls2Container.layer;
    layer.shadowOffset = CGSizeMake(0, -10);
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.3;
    layer.shadowRadius = 15;
    layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;

}


-(BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
