//
//  EmuBaseStyle.h
//  emu
//
//  Created by Aviv Wolf on 2/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class PCGradient;

@interface EmuBaseStyle : NSObject

// Colors
+ (UIColor*)colorMain1;
+ (UIColor*)colorMain2;
+ (UIColor*)colorText1;
+ (UIColor*)colorText2;
+ (UIColor*)colorNavBG;
+ (UIColor*)colorButtonBGPositive;
+ (UIColor*)colorButtonBGNegative;
+ (UIColor*)colorMainBG1;
+ (UIColor*)colorMainBG2;
+ (UIColor*)colorBasicControlFill;
+ (UIColor*)colorBasicControlFillSelected;
+ (UIColor*)colorButtonText;
+ (UIColor*)colorBasicControlStroke;

// Gradients
+ (PCGradient*)gradientSplashBG;
+ (PCGradient*)gradientMainBG;

// Drawing Methods
+ (void)drawLeftPartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected;
+ (void)drawMiddlePartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected;
+ (void)drawRightPartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected;

@end



@interface PCGradient : NSObject
@property(nonatomic, readonly) CGGradientRef CGGradient;
- (CGGradientRef)CGGradient NS_RETURNS_INNER_POINTER;

+ (instancetype)gradientWithColors: (NSArray*)colors locations: (const CGFloat*)locations;
+ (instancetype)gradientWithStartingColor: (UIColor*)startingColor endingColor: (UIColor*)endingColor;

@end
