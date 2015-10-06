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

#import "EMNavBarDelegate.h"
#import "EMNavBarConfigurationSource.h"


@interface EMNavBarVC : UIViewController

/**
 *  The state of the navigation bar (read only - determind by the delegate state).
 */
@property (nonatomic, readonly) NSInteger currentState;

/**
 *  The delegate (usually a related view controller).
 */
@property (nonatomic, weak) id<EMNavBarDelegate> delegate;

/**
 *  A configuration source that controls the configuration of the navigation bar
 *  according to current state.
 */
@property (nonatomic, weak) id<EMNavBarConfigurationSource> configurationSource;

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

/**
 *  A short and simple bounce animation of the navigation bar,
 *  for getting the user's attention.
 */
-(void)bounce;

#pragma mark - Title & Scrolling of child VC
/**
 *  A child view controller is reporting about scrolling.
 *
 *  @param offset CGPoint of the offset of the scroll.
 */
-(void)childVCDidScrollToOffset:(CGPoint)offset;


/**
 *  Updates the title with a new title text.
 *  Possible to animate the transition between previous value and the new one.
 *
 *  @param title    The new title text
 */
-(void)updateTitle:(NSString *)title;

/**
 *  Updates the UI of the navigation bar by current state.
 *  uses the EMNavBarConfigurationSource on each call.
 */
-(void)updateUIByCurrentState;


@end
