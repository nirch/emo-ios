//
//  EMNavBarDelegate.h
//  emu
//
//      \`\ /`/
//       \ V /
//       /. .\
//      =\ T /=
//       / ^ \
//    {}/\\ //\
//    __\ " " /__
//   (____/^\____) Nav Bar Nav! (Homage's inside joke)
//
//  Delegation protocol for communication between the navigation bar and
//  its delegate view controller.
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@protocol EMNavBarDelegate <NSObject>

/**
 *  The state of the delegate.
 */
@property (nonatomic, readonly) NSInteger currentState;

/**
 *  The user pressed the title button in the nav bar.
 *
 *  @param sender The UIButton pressed.
 */
-(void)navBarOnTitleButtonPressed:(UIButton *)sender;

/**
 *  The user pressed the logo button in the nav bar.
 *
 *  @param sender The UIButton pressed.
 */
-(void)navBarOnLogoButtonPressed:(UIButton *)sender;

/**
 *  The user pressed some action button in the navigation bar.
 *  this method will pass the sender button, the current state of
 *  the nav bar and (optional) configuration info about the action.
 *
 *  @param actionName The name of the action as NSString
 *  @param sender     The sender UIButton pressed.
 *  @param state      The current state of the nav bar.
 *  @param info       (optional) extra configuration info.
 */
-(void)navBarOnUserActionNamed:(NSString *)actionName
                        sender:(id)sender
                         state:(NSInteger)state
                          info:(NSDictionary *)info;

/**
 *  The nav bar chosen theme color.
 *
 *  @return <#return value description#>
 */
-(UIColor *)navBarThemeColor;

@end
