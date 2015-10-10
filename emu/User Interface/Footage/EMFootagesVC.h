//
//  EMFootageSelectorVC.h
//  emu
//
//  Created by Aviv Wolf on 10/1/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMInterfaceDelegate.h"

#define emkUIFootageSelectionCancel @"UI footage selection cancel"
#define emkUIFootageSelectionApply @"UI footage selection apply"

@interface EMFootagesVC : UIViewController

/**
 *  Interface delegate to get info and actions back from this VC.
 */
@property (nonatomic, weak) id<EMInterfaceDelegate> delegate;

@property (nonatomic) NSArray *selectedEmusOID;

typedef NS_ENUM(NSInteger, EMFootagesFlowType)
{
    /**
     * Invalid flow type (before initialized properly).
     * VC can't function properly without setting a valid flow type.
     */
    EMFootagesFlowTypeInvalid               = 0,
    
    /**
     *  A screen that allows the user to choose a footage
     *  with options to confirm or cancel the choice.
     */
    EMFootagesFlowTypeChooseFootage               = 1000,
    
    /**
     *  The full footages management screen.
     */
    EMFootagesFlowTypeMangementScreen             = 2000
};

/**
 *  Read only property of the configured flow type for this screen.
 *  Can't be changed after instantiation.
 */
@property (nonatomic, readonly) EMFootagesFlowType flowType;

/**
 *  Factory for instantating and configuring the footages screen.
 *
 *  @param flowType EMFootagesFlowType configures the behaviour and flow
 *
 *          - EMFootagesFlowTypeChooseFootage
 *            a simple screen for choosing footage (with confirm/cancel buttons)
 *
 *
 *          - EMFootagesFlowTypeMangementScreen
 *            full feldged screen for creating, deleting and editing user's takes/footages.
 *
 *  @return A new instance of EMFootagesVC
 */
+(EMFootagesVC *)footagesVCForFlow:(EMFootagesFlowType)flowType;

@end
