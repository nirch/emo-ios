//
//  EmuBaseStyle.m
//  emu
//
//  Created by Aviv Wolf on 4/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import "EmuBaseStyle.h"


@implementation EmuBaseStyle

#pragma mark Cache

static UIColor* _colorMain1 = nil;
static UIColor* _colorMain2 = nil;
static UIColor* _colorText1 = nil;
static UIColor* _colorText2 = nil;
static UIColor* _colorNavBG = nil;
static UIColor* _colorButtonBGPositive = nil;
static UIColor* _colorButtonBGNegative = nil;
static UIColor* _colorMainBG1 = nil;
static UIColor* _colorMainBG2 = nil;
static UIColor* _colorBasicControlFill = nil;
static UIColor* _colorBasicControlFillSelected = nil;
static UIColor* _colorButtonText = nil;
static UIColor* _colorBasicControlStroke = nil;
static UIColor* _colorKBKeyBG = nil;
static UIColor* _colorKBKeyStrongBG = nil;
static UIColor* _colorKBKeyStrongestBG = nil;
static UIColor* _colorKBKeyText = nil;

static PCGradient* _gradientSplashBG = nil;
static PCGradient* _gradientMainBG = nil;

#pragma mark Initialization

+ (void)initialize
{
    // Colors Initialization
    _colorMain1 = [UIColor colorWithRed: 0.404 green: 0.725 blue: 0.275 alpha: 1];
    _colorMain2 = [UIColor colorWithRed: 0.706 green: 0.925 blue: 0.318 alpha: 1];
    _colorText1 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    _colorText2 = [UIColor colorWithRed: 0.29 green: 0.29 blue: 0.29 alpha: 1];
    _colorNavBG = [UIColor colorWithRed: 0.471 green: 0.788 blue: 0.122 alpha: 1];
    _colorButtonBGPositive = [UIColor colorWithRed: 0.471 green: 0.788 blue: 0.122 alpha: 1];
    _colorButtonBGNegative = [UIColor colorWithRed: 1 green: 0 blue: 0.392 alpha: 1];
    _colorMainBG1 = [UIColor colorWithRed: 0.988 green: 0.988 blue: 0.988 alpha: 1];
    _colorMainBG2 = [UIColor colorWithRed: 0.867 green: 0.867 blue: 0.867 alpha: 1];
    _colorBasicControlFill = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0];
    _colorBasicControlFillSelected = [UIColor colorWithRed: 0.494 green: 0.827 blue: 0.129 alpha: 1];
    _colorButtonText = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    _colorBasicControlStroke = [UIColor colorWithRed: 0.847 green: 0.847 blue: 0.847 alpha: 1];
    _colorKBKeyBG = [UIColor colorWithRed: 0.471 green: 0.788 blue: 0.122 alpha: 1];
    _colorKBKeyStrongBG = [UIColor colorWithRed: 0.327 green: 0.538 blue: 0.096 alpha: 1];
    _colorKBKeyStrongestBG = [UIColor colorWithRed: 0.211 green: 0.345 blue: 0.064 alpha: 1];
    _colorKBKeyText = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];

    // Gradients Initialization
    CGFloat gradientSplashBGLocations[] = {0, 1};
    _gradientSplashBG = [PCGradient gradientWithColors: @[EmuBaseStyle.colorMain1, EmuBaseStyle.colorMain2] locations: gradientSplashBGLocations];
    CGFloat gradientMainBGLocations[] = {0, 1};
    _gradientMainBG = [PCGradient gradientWithColors: @[EmuBaseStyle.colorMainBG1, EmuBaseStyle.colorMainBG2] locations: gradientMainBGLocations];

}

#pragma mark Colors

+ (UIColor*)colorMain1 { return _colorMain1; }
+ (UIColor*)colorMain2 { return _colorMain2; }
+ (UIColor*)colorText1 { return _colorText1; }
+ (UIColor*)colorText2 { return _colorText2; }
+ (UIColor*)colorNavBG { return _colorNavBG; }
+ (UIColor*)colorButtonBGPositive { return _colorButtonBGPositive; }
+ (UIColor*)colorButtonBGNegative { return _colorButtonBGNegative; }
+ (UIColor*)colorMainBG1 { return _colorMainBG1; }
+ (UIColor*)colorMainBG2 { return _colorMainBG2; }
+ (UIColor*)colorBasicControlFill { return _colorBasicControlFill; }
+ (UIColor*)colorBasicControlFillSelected { return _colorBasicControlFillSelected; }
+ (UIColor*)colorButtonText { return _colorButtonText; }
+ (UIColor*)colorBasicControlStroke { return _colorBasicControlStroke; }
+ (UIColor*)colorKBKeyBG { return _colorKBKeyBG; }
+ (UIColor*)colorKBKeyStrongBG { return _colorKBKeyStrongBG; }
+ (UIColor*)colorKBKeyStrongestBG { return _colorKBKeyStrongestBG; }
+ (UIColor*)colorKBKeyText { return _colorKBKeyText; }

#pragma mark Gradients

+ (PCGradient*)gradientSplashBG { return _gradientSplashBG; }
+ (PCGradient*)gradientMainBG { return _gradientMainBG; }

#pragma mark Drawing Methods

+ (void)drawLeftPartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();


    //// Variable Declarations
    CGFloat pagerPartOffset = pagerPartIndex * pagerPartWidth;
    UIColor* pgaerIsSelectedColor = pagerPartSelected ? EmuBaseStyle.colorBasicControlFillSelected : EmuBaseStyle.colorBasicControlFill;

    //// part
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, pagerPartOffset, 0);

        CGContextBeginTransparencyLayer(context, NULL);

        //// Clip clipMask
        UIBezierPath* clipMaskPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 30, 17)];
        [clipMaskPath addClip];


        //// rect Drawing
        UIBezierPath* rectPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(3, 1, 31, 15) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft cornerRadii: CGSizeMake(7.5, 7.5)];
        [rectPath closePath];
        [pgaerIsSelectedColor setFill];
        [rectPath fill];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        rectPath.lineWidth = 3;
        [rectPath stroke];


        CGContextEndTransparencyLayer(context);

        CGContextRestoreGState(context);
    }
}

+ (void)drawMiddlePartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();


    //// Variable Declarations
    CGFloat pagerPartOffset = pagerPartIndex * pagerPartWidth;
    UIColor* pgaerIsSelectedColor = pagerPartSelected ? EmuBaseStyle.colorBasicControlFillSelected : EmuBaseStyle.colorBasicControlFill;

    //// part
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, pagerPartOffset, 0);

        CGContextBeginTransparencyLayer(context, NULL);

        //// Clip clipMask
        UIBezierPath* clipMaskPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 30, 17)];
        [clipMaskPath addClip];


        //// rect Drawing
        UIBezierPath* rectPath = [UIBezierPath bezierPathWithRect: CGRectMake(-6, 1, 40, 15)];
        [pgaerIsSelectedColor setFill];
        [rectPath fill];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        rectPath.lineWidth = 3;
        [rectPath stroke];


        //// b4 Drawing
        UIBezierPath* b4Path = UIBezierPath.bezierPath;
        [b4Path moveToPoint: CGPointMake(29, 11)];
        [b4Path addLineToPoint: CGPointMake(29, 15)];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        b4Path.lineWidth = 3;
        [b4Path stroke];


        //// b3 Drawing
        UIBezierPath* b3Path = UIBezierPath.bezierPath;
        [b3Path moveToPoint: CGPointMake(1, 11)];
        [b3Path addLineToPoint: CGPointMake(1, 15)];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        b3Path.lineWidth = 3;
        [b3Path stroke];


        //// b2 Drawing
        UIBezierPath* b2Path = UIBezierPath.bezierPath;
        [b2Path moveToPoint: CGPointMake(29, 1)];
        [b2Path addLineToPoint: CGPointMake(29, 5)];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        b2Path.lineWidth = 3;
        [b2Path stroke];


        //// b1 Drawing
        UIBezierPath* b1Path = UIBezierPath.bezierPath;
        [b1Path moveToPoint: CGPointMake(1, 1)];
        [b1Path addLineToPoint: CGPointMake(1, 5)];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        b1Path.lineWidth = 3;
        [b1Path stroke];


        CGContextEndTransparencyLayer(context);

        CGContextRestoreGState(context);
    }
}

+ (void)drawRightPartWithPagerPartIndex: (CGFloat)pagerPartIndex pagerPartWidth: (CGFloat)pagerPartWidth pagerPartSelected: (BOOL)pagerPartSelected
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();


    //// Variable Declarations
    CGFloat pagerPartOffset = pagerPartIndex * pagerPartWidth;
    UIColor* pgaerIsSelectedColor = pagerPartSelected ? EmuBaseStyle.colorBasicControlFillSelected : EmuBaseStyle.colorBasicControlFill;

    //// part
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, pagerPartOffset, 0);

        CGContextBeginTransparencyLayer(context, NULL);

        //// Clip clipMask
        UIBezierPath* clipMaskPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 30, 17)];
        [clipMaskPath addClip];


        //// rect Drawing
        UIBezierPath* rectPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(-3, 1, 31, 15) byRoundingCorners: UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii: CGSizeMake(7.5, 7.5)];
        [rectPath closePath];
        [pgaerIsSelectedColor setFill];
        [rectPath fill];
        [EmuBaseStyle.colorBasicControlStroke setStroke];
        rectPath.lineWidth = 3;
        [rectPath stroke];


        CGContextEndTransparencyLayer(context);

        CGContextRestoreGState(context);
    }
}

+ (void)drawProgreesBarWithProgressValue: (CGFloat)progressValue
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();


    //// Variable Declarations
    CGFloat frameSize = 400 * progressValue;

    //// Frames
    CGRect frame = CGRectMake(0, 0, frameSize, 36);


    //// Rectangle Drawing
    CGRect rectangleRect = CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), floor((CGRectGetWidth(frame)) * 0.97811 + 0.5), floor((CGRectGetHeight(frame)) * 1.00000 + 0.5));
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: rectangleRect];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, EmuBaseStyle.gradientSplashBG.CGGradient,
        CGPointMake(CGRectGetMinX(rectangleRect), CGRectGetMidY(rectangleRect)),
        CGPointMake(CGRectGetMaxX(rectangleRect), CGRectGetMidY(rectangleRect)),
        0);
    CGContextRestoreGState(context);
}

@end



@interface PCGradient ()
{
    CGGradientRef _CGGradient;
}
@end

@implementation PCGradient

- (instancetype)initWithColors: (NSArray*)colors locations: (const CGFloat*)locations
{
    self = super.init;
    if (self)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSMutableArray* cgColors = NSMutableArray.array;
        for (UIColor* color in colors)
            [cgColors addObject: (id)color.CGColor];

        _CGGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)cgColors, locations);
        CGColorSpaceRelease(colorSpace);
    }
    return self;
}

+ (instancetype)gradientWithColors: (NSArray*)colors locations: (const CGFloat*)locations
{
    return [self.alloc initWithColors: colors locations: locations];
}

+ (instancetype)gradientWithStartingColor: (UIColor*)startingColor endingColor: (UIColor*)endingColor
{
    CGFloat locations[] = {0, 1};
    return [self.alloc initWithColors: @[startingColor, endingColor] locations: locations];
}

- (void)dealloc
{
    CGGradientRelease(_CGGradient);
}

@end
