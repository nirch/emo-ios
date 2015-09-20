//
//  EMNavBarVC.h
//
//    A few instances of this view controller appears in different screens of the app.
//    The navigation bar is customizable (buttons, theme colors etc).
//    The navigation bar is never responsible for actual application flow and functionality.
//    When requires, the nav bar will inform about a button press or event, but will let other
//    view controllers actually handle that event.
//
//  emu
//
//  Created by Aviv Wolf on 9/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import UIKit;

@interface EMNavBarVC : UIViewController

/**
 *  The current theme color of the navigation bar.
 */
@property (nonatomic, readonly) UIColor *themeColor;

/**
 *  Creates and returns a new Navigation bar.
 *
 *  @param parentVC   The parent view controller the nav bar will appear on top of.
 *  @param themeColor The starting theme color used on the instance of the nav bar.
 *
 *  @return new EMNavBarVC instance
 */
+(EMNavBarVC *)navBarVCInParentVC:(UIViewController *)parentVC
                       themeColor:(UIColor *)themeColor;

@end
