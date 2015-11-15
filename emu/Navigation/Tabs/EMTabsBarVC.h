//
//  EMTabsBarVC.h
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - Tabs
/**
 *  The state of the UI.
 */
typedef NS_ENUM(NSInteger, EMTabName){
    EMTabNameFeatured                           = 0,
    EMTabNameFeed                               = 1,
    EMTabNameMe                                 = 2,
    EMTabNameSettings                           = 3,
};

@interface EMTabsBarVC : UIViewController

/**
 *  Select and navigate to a tab at given index.
 *
 *  @param index    NSInteger index of the tab bar to select/navigate to.
 *  @param animated BOOL indicating if to animate the tab selection or not.
 */
-(void)navigateToTabAtIndex:(NSInteger)index animated:(BOOL)animated;


/**
 *  Select and navigate to a tab at given index, and pass info to the selected view controller.
 *
 *  @param index    NSInteger the index to navigate to
 *  @param animated BOOL if to add an animation in the tab bar
 *  @param info     extra info to pass to the destination view cotroller.
 */
-(void)navigateToTabAtIndex:(NSInteger)index animated:(BOOL)animated info:(NSDictionary *)info;


/**
 *  Returns the currently selected tab index.
 *
 *  @return NSInteger of the currently selected tab.
 */
-(NSInteger)currentTabIndex;

@end
