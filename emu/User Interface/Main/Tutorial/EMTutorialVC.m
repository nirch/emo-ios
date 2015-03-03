//
//  EMTutorialVC.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTutorialVC.h"

@interface EMTutorialVC ()

@property (weak, nonatomic) IBOutlet UIView *guiTutorialPresentationContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRightMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeftMargin;

@end

@implementation EMTutorialVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
    [self fixLayout];
}

-(void)initGUI
{
    CALayer *layer = self.guiTutorialPresentationContainer.layer;
    layer.cornerRadius = 10;
    layer.borderWidth = 7;
    layer.borderColor = [UIColor whiteColor].CGColor;
}

-(void)fixLayout
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight > 480.0) return;
    
    // Fu@#$%ing iPhone 4s needs special treatment of the layout.
    self.constraintLeftMargin.constant = 60;
    self.constraintRightMargin.constant = -60;

}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedContinueButton:(id)sender
{
    [self.delegate controlSentActionNamed:@"keyboard tutorial should be dismissed" info:nil];
}


@end
