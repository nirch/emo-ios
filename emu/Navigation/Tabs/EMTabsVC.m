//
//  EMTabsVC.m
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTabsVC.h"

#import "EMTestVC.h"
#import "EMNotificationCenter.h"
#import "EmuStyle.h"
#import "EMPacksVC.h"
#import "EMFeedNavigationVC.h"
#import "EMMeNavigationVC.h"
#import "EMSettingsNavigationVCViewController.h"
#import "EMTopVCProtocol.h"
#import "EMUINotifications.h"

@interface EMTabsVC ()

@property (nonatomic) BOOL initializedViewControllers;

@end

@implementation EMTabsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.initializedViewControllers = NO;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.initializedViewControllers) {
        [self initViewControllers];
        self.initializedViewControllers = YES;
    }
    
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onTabSelected:)
                     name:emkUINavigationTabSelected
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkUINavigationTabSelected];
}

#pragma mark - Observers handlers
-(void)onTabSelected:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *newTabIndexNumber = info[@"newTabIndex"];
    NSInteger newTabIndex = [newTabIndexNumber integerValue];
    self.selectedIndex = newTabIndex;
    
    // Tell selected view controller it was chosen.
    id<EMTopVCProtocol>selectedVC = self.childViewControllers[self.selectedIndex];
    if ([selectedVC conformsToProtocol:@protocol(EMTopVCProtocol)]) {
        [selectedVC vcWasSelectedWithInfo:info];
    }
}

#pragma mark - initializations
/**
 * Populate the tabs controller with child view controllers.
 */
-(void)initViewControllers
{
    NSMutableArray *viewControllers = [NSMutableArray new];
    
    // Featured
    UIViewController *featuredPacksVC = [EMPacksVC packsVCWithFeaturedPacks];
    featuredPacksVC.title = @"Featured";
    [viewControllers addObject:featuredPacksVC];
    
    // Feed
    UIViewController *feedVC = [EMFeedNavigationVC feedNavigationVC];
    feedVC.title = @"Feed";
    [viewControllers addObject:feedVC];
    
//    // Search
//    UIViewController *searchVC = [EMTestVC testVCWithFrame:f backgroundColor:[EmuStyle colorThemeSearch]];
//    searchVC.title = @"Search";
//    [viewControllers addObject:searchVC];
    
    // Me screen
    UIViewController *meVC = [EMMeNavigationVC meNavigationVC];
    meVC.title = @"Me";
    [viewControllers addObject:meVC];
    
    // Settings
    UIViewController *settingsVC = [EMSettingsNavigationVCViewController settingsNavVC];
    settingsVC.title = @"Settings";
    [viewControllers addObject:settingsVC];
    
    self.viewControllers = viewControllers;
}

@end
