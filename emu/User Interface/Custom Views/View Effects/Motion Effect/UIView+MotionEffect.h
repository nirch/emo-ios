//
//  UIView+MotionEffect.h
//
//  A category on UIView. Adds two helper methods that allows to add a simple version of the iOS7 motion effect
//  to any view, with a single line of code.
//
//  Created by Aviv Wolf on 10/15/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

@interface UIView (MotionEffect)

-(void)addMotionEffectWithAmount:(double)amount;
-(void)addMotionEffectWithAmountX:(double)amountX amountY:(double)amountY;

@end
