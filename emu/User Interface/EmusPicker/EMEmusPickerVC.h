//
//  EMEmusPickerVC.h
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMInterfaceDelegate.h"

#define emkUIActionPickedEmu  @"UI action picked emu with oid"

@interface EMEmusPickerVC : UIViewController

@property (nonatomic, weak) id<EMInterfaceDelegate> delegate;
@property (nonatomic) NSString *identifier;

#pragma mark - helper configurators

/**
 *  Helper for easilly configuring the VC to
 *  to display a list of favorite emus.
 */
-(void)configureForFavoriteEmus;

/**
 *  Helper for easilly configuring the VC to
 *  display a list of recently viewed emus.
 */
-(void)configureForRecentlyViewedEmus;

/**
 *  Helper for easilly configuring the VC to
 *  display a list of recently shared emus.
 */
-(void)configureForRecentlySharedEmus;

#pragma mark - Reload
/**
 *  Refreshes the displayed data from local storage.
 */
-(void)refreshLocalData;

@end
