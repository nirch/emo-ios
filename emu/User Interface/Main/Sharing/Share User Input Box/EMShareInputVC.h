//
//  EMShareInputViewController.h
//  emu
//
//  Created by Aviv Wolf on 8/18/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMShareInputDelegate.h"

@interface EMShareInputVC : UIViewController

+(EMShareInputVC *)shareInputVCInParentVC:(UIViewController *)parentVC;

@property (nonatomic, weak) id<EMShareInputDelegate> delegate;

@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIImage *titleIcon;
@property (nonatomic) UIImage *sharedMediaIcon;
@property (nonatomic) NSString *defaultHashTags;

#pragma mark - Show/Hide
-(void)updateUI;
-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animated;
-(void)cleanup;

@end
