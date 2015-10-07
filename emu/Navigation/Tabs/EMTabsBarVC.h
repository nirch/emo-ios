//
//  EMTabsBarVC.h
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMTabsBarVC : UIViewController

/**
 *  Select and navigate to a tab at given index.
 *
 *  @param index    NSInteger index of the tab bar to select/navigate to.
 *  @param animated BOOL indicating if to animate the tab selection or not.
 */
-(void)navigateToTabAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
