//
//  EMunizingView.h
//  emu
//
//  Created by Aviv Wolf on 2/24/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMunizingView : UIView

@property (nonatomic, readonly) BOOL isAnimating;

-(void)setup;
-(void)startAnimating;
-(void)stopAnimating;

@end
