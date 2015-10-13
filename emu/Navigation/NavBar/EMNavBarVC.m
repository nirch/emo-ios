//
//  NavBarVC.m
//  emu
//
//  Created by Aviv Wolf on 9/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMNavBarVC.h"
#import "EMNotificationCenter.h"
#import "EMUISound.h"
#import "AppManagement.h"

#define TAG @"EMNavBarVC"
#define ARC4RANDOM_MAX 0x100000000


@interface EMNavBarVC ()

@property (nonatomic, readwrite) UIColor *themeColor;

@property (weak, nonatomic) IBOutlet UIView *guiNavView;
@property (weak, nonatomic) IBOutlet UIView *guiSeparator;
@property (weak, nonatomic) IBOutlet UIView *guiLogoButtonBG;
@property (weak, nonatomic) IBOutlet UIButton *guiLogoButton;
@property (weak, nonatomic) IBOutlet UIButton *guiLogoAlternateButton;
@property (weak, nonatomic) IBOutlet UIButton *guiTitle;

@property (weak, nonatomic) IBOutlet UIButton *guiActionButton1;
@property (weak, nonatomic) IBOutlet UIButton *guiActionButton2;

@property (nonatomic) NSDictionary *cfg;

@property (nonatomic) CGPoint logoButtonOriginalCenter;

@property (nonatomic) BOOL alreadyInitializedUIBeforeApearance;
@property (nonatomic) BOOL alreadyInitializedUIOnApearance;

@property (nonatomic) BOOL ignoreActions;

@end

@implementation EMNavBarVC

+(EMNavBarVC *)navBarVCInParentVC:(UIViewController *)parentVC
                       themeColor:(UIColor *)themeColor
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NavBar" bundle:nil];
    EMNavBarVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"nav bar vc"];
    vc.themeColor = themeColor;
    
    // Add to parent view controller
    [parentVC addChildViewController:vc];
    
    // Add as a subview of the main view of the parent view controller.
    // Will fill the width of the parent and appear at the top.
    CGRect f = parentVC.view.bounds;
    f.size.height = 52;
    vc.view.frame = f;
    [parentVC.view addSubview:vc.view];
    
    // Ready. Return the new VC instance.
    return vc;
}

#pragma mark - VC lifecycle
-(void)viewDidLoad {
    [super viewDidLoad];
    [self initGUIOnLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUIBeforeApearance];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUIOnApearance];
}

#pragma mark - Initializations
-(void)initGUIOnLoad
{
    self.alreadyInitializedUIOnApearance = NO;
    self.alreadyInitializedUIBeforeApearance = NO;
    self.view.alpha = 0;
    self.guiActionButton1.hidden = YES;
    self.guiActionButton2.hidden = YES;
    self.ignoreActions = NO;
    
    CALayer *l = self.guiLogoAlternateButton.layer;
    l.cornerRadius = l.bounds.size.width/2.0f;
    l.borderColor = [UIColor whiteColor].CGColor;
    l.borderWidth = 3.0f;
    self.guiLogoAlternateButton.backgroundColor = [UIColor clearColor];
    self.guiLogoAlternateButton.alpha = 0;
    self.guiLogoAlternateButton.clipsToBounds = YES;
}

-(void)initGUIBeforeApearance
{
    if (!self.alreadyInitializedUIBeforeApearance) {
        // Set the theme color.
        [self updateThemeColor:self.themeColor animated:NO];
        
        // Title
        self.guiTitle.hidden = NO;
        [self hideTitleAnimated:NO];
                
        // Round logo button
        self.guiLogoButtonBG.layer.cornerRadius = self.guiLogoButtonBG.bounds.size.width / 2.0f;
        [self addSubtleShadowToLayer:self.guiLogoButtonBG.layer boundPath:NO];

        // Show it
        self.view.alpha = 1;
        
        // Mark as already initialized
        self.alreadyInitializedUIBeforeApearance = YES;
    }
}

-(void)initGUIOnApearance
{
    if (!self.alreadyInitializedUIOnApearance) {
        // Add subtle shadow to the navigation bar
        [self addSubtleShadowToLayer:self.guiNavView.layer boundPath:YES];
        
        // Round logo button position
        // Yeah yeah, I know. position should be taken from containing view
        // and not from screen size. Just a hack for now.
        // Got more important thing to take care of.
        // TODO: fix this.
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        self.logoButtonOriginalCenter = CGPointMake(screenWidth/2.0f, 32);

        // Mark as already initialized
        self.alreadyInitializedUIOnApearance = YES;
    }
}

-(void)addSubtleShadowToLayer:(CALayer *)layer boundPath:(BOOL)boundPath
{
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowRadius = 2;
    layer.shadowOpacity = 0.15;
    layer.shadowOffset = CGSizeMake(0, 4);
    if (boundPath) {
        layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
    }
}

#pragma mark - Animations
-(void)bounce
{
    [UIView animateWithDuration:0.4 animations:^{
        CGFloat dx =  ((float)arc4random() / ARC4RANDOM_MAX) * 0.3f;
        CGFloat dy =  ((float)arc4random() / ARC4RANDOM_MAX) * 0.3f;
        self.guiLogoButton.transform = CGAffineTransformMakeScale(1.0f+dx, 1.0f+dy);
        self.guiLogoButtonBG.transform = CGAffineTransformMakeScale(1.0f+dx, 1.0f+dy);
        self.guiLogoAlternateButton.transform = CGAffineTransformMakeScale(1.0f+dx, 1.0f+dy);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.guiLogoButton.transform = CGAffineTransformIdentity;
                             self.guiLogoButtonBG.transform = CGAffineTransformIdentity;
                             self.guiLogoAlternateButton.transform = CGAffineTransformIdentity;
                         } completion:nil];
    }];
}


#pragma mark - Theme color
-(void)updateThemeColor:(UIColor *)color animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self updateThemeColor:color animated:NO];
        }];
        return;
    }
    
    // Update the theme color.
    _themeColor = color;
    self.guiLogoButtonBG.backgroundColor = color;
    self.guiNavView.backgroundColor = color;
}

#pragma mark - Title & Scrolling of child VC
-(void)childVCDidScrollToOffset:(CGPoint)offset
{
    CGPoint center = self.logoButtonOriginalCenter;
    center.y -= offset.y;
    CGFloat dy = self.logoButtonOriginalCenter.y - center.y;
    
    if (dy <= 0) {
        self.guiLogoButton.center = self.logoButtonOriginalCenter;
        self.guiLogoButtonBG.center = self.logoButtonOriginalCenter;
    } else {
        self.guiLogoButton.center = center;
        self.guiLogoButtonBG.center = center;
    }
    
    if (dy < 20) {
        if (self.guiTitle.alpha == 1) {
            [self hideTitleAnimated:YES];
        }
    } else {
        if (self.guiTitle.alpha == 0) {
            [self showTitleAnimated:YES];
        }
    }
    
}

-(void)hideTitleAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self hideTitleAnimated:NO];
        } completion:nil];
        return;
    }
    
    self.guiLogoButton.alpha = 1;
    self.guiLogoButtonBG.alpha = 1;
    self.guiTitle.alpha = 0;
    self.guiTitle.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
}

-(void)showTitleAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self showTitleAnimated:NO];
                         } completion:nil];
        return;
    }
    
    self.guiLogoButton.alpha = 0;
    self.guiLogoButtonBG.alpha = 0;
    self.guiTitle.alpha = 1;
    self.guiTitle.transform = CGAffineTransformIdentity;
    
}

-(void)showImageAsLogo:(UIImage *)image
{
    [self.guiLogoAlternateButton setImage:image forState:UIControlStateNormal];
    [UIView animateWithDuration:0.3 animations:^{
        self.guiLogoButton.alpha = 0;
        self.guiLogoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.guiLogoAlternateButton.alpha = 1;
    } completion:^(BOOL finished) {
        self.guiLogoButton.hidden = YES;
        [self bounce];
    }];
}

-(void)updateTitle:(NSString *)title
{
    [UIView setAnimationsEnabled:NO];
    [self.guiTitle setTitle:title forState:UIControlStateNormal];
    [self.guiTitle layoutIfNeeded];
    [UIView setAnimationsEnabled:YES];
    
    if (self.guiTitle.alpha != 0) {
        self.guiTitle.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        [EMUISound.sh playSoundNamed:SND_POP];
        [self showTitleAnimated:YES];
    }
}

-(void)updateTitleAlpha:(CGFloat)alpha
{
    self.guiTitle.alpha = alpha;
}


#pragma mark - State
-(NSInteger)currentState
{
    if (self.delegate == nil) return 0;
    return [self.delegate currentState];
}

-(void)updateUIByCurrentState
{
    if (self.configurationSource == nil) return;
    if (self.currentState == 0) return;
    
    // Get the new configuration for current state.
    self.cfg = [self.configurationSource navBarConfigurationForState:self.currentState];
    if (self.cfg == nil) {
        self.cfg = @{};
        HMLOG(TAG, EM_ERR, @"Unsupported state/configuration for navigation bar");
    }
    [self updateUIWithCurrentCFG];
}

-(void)updateUIWithCurrentCFG
{
    // By default, hide the action buttons.
    self.guiActionButton1.hidden = YES;
    self.guiActionButton2.hidden = YES;
    
    // Config and show buttons as required, according to configuration.
    
    // Action button 1
    [self _updateActionButton:self.guiActionButton1 withCFG:self.cfg[EMK_NAV_ACTION_1]];
    
    // Action button 2
    [self _updateActionButton:self.guiActionButton2 withCFG:self.cfg[EMK_NAV_ACTION_2]];
}

-(void)_updateActionButton:(UIButton *)actionButton withCFG:(NSDictionary *)cfg
{
    if (actionButton == nil || cfg == nil) return;
    
    if (cfg[EMK_NAV_ACTION_ICON]) {
        
        // Set Icon
        [actionButton setTitle:nil forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:cfg[EMK_NAV_ACTION_ICON]] forState:UIControlStateNormal];
        actionButton.hidden = NO;
        
    } else if (cfg[EMK_NAV_ACTION_TEXT]) {
        
        // Set Text
        [actionButton setTitle:cfg[EMK_NAV_ACTION_TEXT] forState:UIControlStateNormal];
        [actionButton setImage:nil forState:UIControlStateNormal];
        actionButton.hidden = NO;
        
    }
}

#pragma mark - Actions
-(void)executeActionWithActionCFG:(NSDictionary *)actionCFG sender:(id)sender
{
    if (actionCFG == nil || self.currentState == 0) {
        HMLOG(TAG, EM_ERR, @"Unsupported action");
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{
                                                        @"msg":@"Unsupported action",
                                                        @"action":@"unrecognized",
                                                        @"state":@(self.currentState)
                                                        }];
        return;
    }
    
    // Tell the delegate to execute the action.
    [self.delegate navBarOnUserActionNamed:actionCFG[EMK_NAV_ACTION_NAME]
                                    sender:sender
                                     state:self.currentState
                                      info:actionCFG[EMK_NAV_ACTION_INFO]];
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedTitleButton:(UIButton *)sender
{
    [self.delegate navBarOnTitleButtonPressed:sender];
}

- (IBAction)onPressedFaceButton:(UIButton *)sender
{
    if (AppManagement.sh.isTestApp) {
        [[NSNotificationCenter defaultCenter] postNotificationName:emkDataDebug object:self userInfo:nil];
    }
}

- (IBAction)onActionButton1Pressed:(id)sender
{
    if (self.ignoreActions) return;

    NSDictionary *actionCFG = self.cfg[EMK_NAV_ACTION_1];
    [self executeActionWithActionCFG:actionCFG sender:sender];
    BOOL ignoreActions = self.ignoreActions;
    self.ignoreActions = YES;
    dispatch_after(DTIME(0.7), dispatch_get_main_queue(), ^{
        self.ignoreActions = ignoreActions;
    });    
}

- (IBAction)onActionButton2Pressed:(id)sender
{
    if (self.ignoreActions) return;
    
    NSDictionary *actionCFG = self.cfg[EMK_NAV_ACTION_2];
    [self executeActionWithActionCFG:actionCFG sender:sender];
    BOOL ignoreActions = self.ignoreActions;
    self.ignoreActions = YES;
    dispatch_after(DTIME(0.7), dispatch_get_main_queue(), ^{
        self.ignoreActions = ignoreActions;
    });
}


@end
