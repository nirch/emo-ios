//
//  EMBGFeedBackViewController.h
//  emu
//
//  Created by Aviv Wolf on 2/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMBGFeedBackVC : UIViewController

@property (nonatomic) CGFloat goodBackgroundWeight;

-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animted;

@end
