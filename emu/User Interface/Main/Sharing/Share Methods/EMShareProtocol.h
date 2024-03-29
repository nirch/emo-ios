//
//  EMShareProtocol.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareDelegate.h"

// Specific apps
typedef NS_ENUM(NSInteger, EMKShareMethod) {
    emkShareMethodFacebook                              = 1000,
    emkShareMethodWhatsapp                              = 2000,
    emkShareMethodSaveToCameraRoll                      = 3000,
    emkShareMethodMail                                  = 4000,
    emkShareMethodCopy                                  = 5000,
    emkShareMethodFacebookMessanger                     = 6000,
    emkShareMethodAppleMessages                         = 7000,
    emkShareMethodOther                                 = 8000,
    emkShareMethodFile                                  = 9000,
    emkShareMethodDocumentInteraction                   = 10000,
    emkShareMethodTwitter                               = 11000,
    emkShareMethodInstagram                             = 12000,
};

// What to share?
typedef NS_ENUM(NSInteger, EMKShareOption) {
    emkShareOptionAnimatedGif           = 0,
    emkShareOptionVideo                 = 1,
    emkShareText                        = 2,
    emkShareHTML                        = 3
};



@protocol EMShareProtocol <NSObject>

@property (nonatomic, weak) id<EMShareDelegate> delegate;

/**
 *  The object to share. This must be set and used in all implementations.
 */
@property (nonatomic) id objectToShare;


/**
 *  Option of what to share.
 */
@property (nonatomic) EMKShareOption shareOption;

/**
 *  Some info about the share.
 */
@property (nonatomic) NSMutableDictionary *info;
@property (nonatomic) NSMutableDictionary *extraCFG;


@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) UIView *view;

-(void)share;
-(void)cleanUp;

@end
