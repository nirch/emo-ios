//
//  EMProgressView.h
//  emu
//
//  Created by Aviv Wolf on 2/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMProgressView : UIView

@property (nonatomic, readonly) CGFloat value;

-(void)reset;
-(void)setValue:(CGFloat)value
       animated:(BOOL)animated
       duration:(NSTimeInterval)duration;

@end
