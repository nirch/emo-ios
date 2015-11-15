//
//  EMFullScreenGifPlayer.m
//  emu
//
//  Created by Aviv Wolf on 05/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFullScreenGifPlayer.h"
#import <FLAnimatedImageView.h>
#import <UIImageView+PINRemoteImage.h>

@interface EMFullScreenGifPlayer ()

@property (weak, nonatomic) IBOutlet UIView *guiActionBar;
@property (weak, nonatomic) IBOutlet UILabel *guiResolutionLabel;
@property (weak, nonatomic) IBOutlet FLAnimatedImageView *animatedGifImage;
@property (weak, nonatomic) IBOutlet UIView *guiActionBarBlurryBG;

@property (nonatomic) BOOL alreadyInitializedGUIOnFirstAppearance;

@end

@implementation EMFullScreenGifPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUIOnLoad];
    [self loadAnimatedGif];
    [self hideActionBarAnimated:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.alreadyInitializedGUIOnFirstAppearance) {
        //
        // Add blur effect to the background.
        //
        self.guiActionBarBlurryBG.backgroundColor = [UIColor clearColor];
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        visualEffectView.frame = CGRectMake(0, 0, 1200, 39);
        [self.guiActionBarBlurryBG addSubview:visualEffectView];
    }
}

-(void)initGUIOnLoad
{
    self.view.backgroundColor = [UIColor blackColor];
    self.alreadyInitializedGUIOnFirstAppearance = NO;
    self.guiActionBar.backgroundColor = [UIColor clearColor];
    self.guiResolutionLabel.text = @"";
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)loadAnimatedGif
{
    [self.animatedGifImage pin_setImageFromURL:self.gifURL completion:^(PINRemoteImageManagerResult *result) {
        CGFloat width = result.animatedImage.size.width;
        CGFloat height = result.animatedImage.size.height;
        if (width>0 && height>0) {
            [self updateResolutionLabelWithSize:CGSizeMake(width, height)];
            dispatch_after(DTIME(1.5f), dispatch_get_main_queue(), ^{
                [self showActionBarAnimated:YES];
                dispatch_after(DTIME(1.5f), dispatch_get_main_queue(), ^{
                    [self hideActionBarAnimated:YES];
                });
            });
        }
    }];
}

-(void)updateResolutionLabelWithSize:(CGSize)size
{
    self.guiResolutionLabel.text = [SF:@"%@ x %@", @(size.width), @(size.height)];
}

#pragma mark - Action bar show / hide
-(void)toggleActionBar
{
    if (self.guiActionBar.alpha < 1.0) {
        [self showActionBarAnimated:YES];
    } else {
        [self hideActionBarAnimated:YES];
    }
}

-(void)showActionBarAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showActionBarAnimated:NO];
            return;
        }];
    }
    
    self.guiActionBar.alpha = 1.0;
    self.guiActionBar.transform = CGAffineTransformIdentity;
}

-(void)hideActionBarAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self hideActionBarAnimated:NO];
            return;
        }];
    }
    
    self.guiActionBar.alpha = 0.0;
    self.guiActionBar.transform = CGAffineTransformMakeTranslation(0, 40);
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedToggleActionBarButton:(id)sender
{
    [self toggleActionBar];
}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
