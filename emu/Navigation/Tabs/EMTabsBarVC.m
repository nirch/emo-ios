//
//  EMTabsBarVC.m
//  emu
//
//  View controller implementing the custom main tab bar of the application.
//
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTabsBarVC.h"

#import "EMUISound.h"
#import "EMNotificationCenter.h"
#import "EmuStyle.h"

#define SELECTOR_HEIGHT 4.0f

@interface EMTabsBarVC ()

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *guiTabsBarButtons;
@property (weak, nonatomic) IBOutlet UIView *guiTabsSeparator;

@property (nonatomic) BOOL alreadyInitializedGUI;
@property (nonatomic, weak) UIView *selectorView;
@property (nonatomic) NSArray *tabsThemeColors;

// State
@property (nonatomic) NSInteger selectedTab;

@end

@implementation EMTabsBarVC

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.alreadyInitializedGUI = NO;
    self.selectedTab = 0;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateSelectorAnimated:NO];
    [self updateThemeAnimated:NO];
}


#pragma mark - Initializations
-(void)initGUI
{
    if (self.alreadyInitializedGUI) return;
    // Create the selector view
    [self initTabsThemeColors];
    [self initSelectorView];
    
    self.alreadyInitializedGUI = YES;
}

-(void)initTabsThemeColors
{
    self.tabsThemeColors = @[
                             [EmuStyle colorThemeFeatured],
                             [EmuStyle colorThemeFeed],
                             [EmuStyle colorThemeSearch],
                             [EmuStyle colorThemeMe],
                             [EmuStyle colorThemeSettings]
                             ];
}

#pragma mark - Selector view
-(void)initSelectorView
{
    if (self.selectorView) return;
    
    UIView *selectorView = [[UIView alloc] initWithFrame:[self selectorFrameForIndex:0]];
    selectorView.backgroundColor = self.guiTabsSeparator.backgroundColor;
    [self.view addSubview:selectorView];
    self.selectorView = selectorView;
    [self updateSelectorAnimated:NO];
    [self updateThemeAnimated:NO];
}

-(CGRect)selectorFrameForIndex:(NSInteger)index
{
    UIButton *button = self.guiTabsBarButtons[0];
    CGRect frame = button.bounds;
    frame.origin.y = frame.size.height - SELECTOR_HEIGHT;
    frame.origin.x = index * frame.size.width;
    frame.size.height = SELECTOR_HEIGHT;
    return frame;
}

-(void)updateSelectorAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.7
                              delay:0.2
             usingSpringWithDamping:0.5
              initialSpringVelocity:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self updateSelectorAnimated:NO];
                         } completion:nil];
        return;
    }
    
    // Reposition selector view frame.
    self.selectorView.frame = [self selectorFrameForIndex:self.selectedTab];
}

#pragma mark - Theme colors
-(void)updateThemeAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateThemeAnimated:NO];
        }];
        return;
    }
    
    UIColor *themeColor = [self themeColor];
    self.guiTabsSeparator.backgroundColor = themeColor;
    self.selectorView.backgroundColor = themeColor;
}

-(UIColor *)themeColor
{
    UIColor *themeColor = self.tabsThemeColors[self.selectedTab];
    return themeColor;
}

#pragma mark - UI Animations
-(void)flickerButton:(UIButton *)button
{
    // Flicker button.
    [UIView animateWithDuration:0.2
                     animations:^{
                         button.backgroundColor = [self themeColor];
                         button.alpha = 0.1;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              button.backgroundColor = [UIColor clearColor];
                                              button.alpha = 1;
                                          } completion:nil];
                     }];

}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========

/**
 *  User pressed one of the tab bar buttons.
 *
 *  If the tab pressed is the same as the current selected tab, will do nothing.
 *
 *  @param sender The button pressed.
 */
- (IBAction)onPressedTabButton:(UIButton *)sender
{
    // Get the related tab index.
    NSInteger index = sender.tag;
    if (index == self.selectedTab) return;

    // Click sound
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];

    // Broadcast that a tab was selected to whoever is interested.
    NSDictionary *info = @{
                           @"previousTabIndex":@(self.selectedTab),
                           @"newTabIndex":@(index)
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUINavigationTabSelected
                                                        object:self
                                                      userInfo:info];

    // Update animations.
    self.selectedTab = index;
    [self updateThemeAnimated:YES];
    [self flickerButton:sender];
    [self updateSelectorAnimated:YES];
}



@end
