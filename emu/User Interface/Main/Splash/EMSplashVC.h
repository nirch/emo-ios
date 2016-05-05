//
//  EMSplashVC.h
//  emu
//
//  Created by Aviv Wolf on 3/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMSplashVC : UIViewController

+(EMSplashVC *)splashVCInParentVC:(UIViewController *)parentVC;

-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animted;
-(void)setText:(NSString *)text;
-(void)removeFromViewHeirarchy;

@end
