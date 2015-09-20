//
//  EMPacksVC.h
//  emu
//
//  Showing list of packs.
//  When user selectes a pack, it will be shown to the user on the main feed.
//  This VC can also embed the featured packs VC at the top (determined on instansciation).
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import UIKit;

@interface EMPacksVC : UIViewController

/**
 *  YES if the featured packs are embedded and shown at the top of the list.
 *  NO otherwise.
 *  This is a read only property that is determind on instantiation.
 */
@property (nonatomic, readonly) BOOL featuredPacksShown;

/**
 *  Instantiates a new instance of the packs view controller.
 *  The featured packs VC will not be shown.
 *  Uses theme colors as defined in EmuStyle.h
 *
 *  @return A new EMPacksVC instance.
 */
+(EMPacksVC *)packsVC;

/**
 *  Instantiates a new instance of the packs view controller.
 *  The featured packs VC will be embedded and shown at the top.
 *  Uses theme colors as defined in EmuStyle.h
 *
 *  @return A new EMFeaturedVC instance.
 */
+(EMPacksVC *)packsVCWithFeaturedPacks;


@end
