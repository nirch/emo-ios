//
//  NavBarVC.m
//  emu
//
//  Created by Aviv Wolf on 9/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMNavBarVC.h"
#import "EMNotificationCenter.h"

#define ARC4RANDOM_MAX 0x100000000


@interface EMNavBarVC ()

@property (nonatomic, readwrite) UIColor *themeColor;

@property (weak, nonatomic) IBOutlet UIView *guiNavView;
@property (weak, nonatomic) IBOutlet UIView *guiSeparator;
@property (weak, nonatomic) IBOutlet UIView *guiLogoButtonBG;
@property (weak, nonatomic) IBOutlet UIButton *guiLogoButton;

@property (nonatomic) BOOL alreadyInitializedUI;

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
    f.size.height = 57;
    vc.view.frame = f;
    [parentVC.view addSubview:vc.view];
    
    // Ready. Return the new VC instance.
    return vc;
}

#pragma mark -
-(void)viewDidLoad {
    [super viewDidLoad];
    self.alreadyInitializedUI = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initGUI];
}

#pragma mark - Initializations
-(void)initGUI
{
    if (!self.alreadyInitializedUI) {
        // Set the theme color.
        [self updateThemeColor:self.themeColor animated:NO];
        
        // Add subtle shadow to the navigation bar
        [self addSubtleShadowToLayer:self.guiNavView.layer boundPath:YES];
        
        // Round logo button
        self.guiLogoButtonBG.layer.cornerRadius = self.guiLogoButtonBG.bounds.size.width / 2.0f;
        [self addSubtleShadowToLayer:self.guiLogoButtonBG.layer boundPath:NO];
        
        // Mark as already initialized
        self.alreadyInitializedUI = YES;
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
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.guiLogoButton.transform = CGAffineTransformIdentity;
                             self.guiLogoButtonBG.transform = CGAffineTransformIdentity;
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

- (IBAction)onPressedFaceButton:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataDebug object:self userInfo:nil];
}

@end
