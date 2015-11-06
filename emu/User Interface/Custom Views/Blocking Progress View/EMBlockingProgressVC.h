//
//  EMBlockingProgressViewController.h
//  emu
//
//  Created by Aviv Wolf on 06/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMBlockingProgressVC : UIViewController

+(EMBlockingProgressVC *)blockingProgressVCInParentVC:(UIViewController *)parentVC;

-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animated;
-(void)updateProgress:(CGFloat)progress animated:(BOOL)animated;
-(void)updateTitle:(NSString *)title;
-(void)done;

@end
