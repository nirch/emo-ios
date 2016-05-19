//
//  EMGradientView.m
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


/** DEPRECATED!!! **/
/**
 *  All background gradient views are deprecated.
 *  Simple solid background views will now be used instead.
 */
#import "EMGradientView.h"

@interface EMGradientView()

@property (nonatomic, weak) PCGradient* gradient;

@end

@implementation EMGradientView

-(void)setGradientName:(NSString *)gradientName
{
    // Deprecated. Do nothing.
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Deprecated the custom gradient views in emu.
        // Replaced with hard coded view containing a small low res stretched UIImage.
        // Reason: all gradient background in the app were exectly the same and the solution with the UIImage
        // has lower memory consumption.
        UIImageView *containedImageView = [UIImageView new];
        CGRect frame = self.bounds;
        frame = CGRectInset(frame, 0, 20);
        containedImageView.frame = frame;
        containedImageView.image = [UIImage imageNamed:@"gradientBG"];
        containedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:containedImageView];
        [self sendSubviewToBack:containedImageView];
    }
    return self;
}

@end
