//
//  EMTutorialVC.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import AVKit;
@import AVFoundation;
#import "EMTutorialVC.h"

@interface EMTutorialVC ()

@property (weak, nonatomic) IBOutlet UIView *guiTutorialPresentationContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRightMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeftMargin;

@property (weak, nonatomic) AVPlayerViewController *avPlayerVC;

@property (nonatomic) BOOL alreadyInitializedEffects;

@end

@implementation EMTutorialVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.alreadyInitializedEffects = NO;
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

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"tutorial video player segue"]) {
        self.avPlayerVC = segue.destinationViewController;
        self.avPlayerVC.showsPlaybackControls = NO;
    }
}


#pragma mark - Play/Stop
-(void)start
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"kbAllowAccessTutorial" withExtension:@"mp4"];
    self.avPlayerVC.player = [AVPlayer playerWithURL:url];
    AVPlayer *player = self.avPlayerVC.player;

    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(playerItemDidReachEnd:)
                                                       name:AVPlayerItemDidPlayToEndTimeNotification
                                                     object:[player currentItem]];
    
    [self.avPlayerVC.player play];
}

-(void)finish
{
    [self.avPlayerVC.player pause];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:AVPlayerItemDidPlayToEndTimeNotification];
}

#pragma mark - Looping!
-(void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
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
