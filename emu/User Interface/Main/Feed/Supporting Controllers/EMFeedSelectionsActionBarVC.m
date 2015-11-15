//
//  EMFeedSelectionsActionBarVC.m
//  emu
//
//  Created by Aviv Wolf on 10/5/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@import AudioToolbox;

#import "EMFeedSelectionsActionBarVC.h"
#import "UIView+CommonAnimations.h"
#import "EMFlowButton.h"
#import "UIView+CommonAnimations.h"

@interface EMFeedSelectionsActionBarVC ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredBG;
@property (weak, nonatomic) IBOutlet UILabel *guiSelectedCountLabel;

@property (weak, nonatomic) IBOutlet EMFlowButton *guiRecorderButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiChangeTakeButton;

@property (nonatomic) BOOL alreadyInitializedOnAppearance;

@end

@implementation EMFeedSelectionsActionBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.alreadyInitializedOnAppearance = NO;
    self.selectedCount = 0;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.alreadyInitializedOnAppearance) {
        //
        // Add blur effect to the background.
        //
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        visualEffectView.frame = self.guiBlurredBG.bounds;
        [self.guiBlurredBG addSubview:visualEffectView];
        
        self.alreadyInitializedOnAppearance = YES;
    }
}

#pragma mark - Error
-(void)communicateErrorToUser
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    // Shake the wrong number
    [self.guiSelectedCountLabel animateShortVibration];
}

#pragma mark - Selections count
-(void)setSelectedCount:(NSInteger)value
{
    _selectedCount = value;
    self.guiSelectedCountLabel.text = [SF:@"%@",@(value)];
    self.guiSelectedCountLabel.alpha = value == 0 ? 0.5:1.0;
    [self.guiSelectedCountLabel animateQuickPopIn];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onRetakeButtonPressed:(id)sender
{
    [self.delegate controlSentActionNamed:emkSelectionsActionRetakeSelected info:nil];
}

- (IBAction)onReplaceTakeButtonPressed:(id)sender
{
    [self.delegate controlSentActionNamed:emkSelectionsActionReplaceSelected info:nil];
}



@end
