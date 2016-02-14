//
//  EmuStyle.m
//  emu
//
//  Created by Aviv Wolf on 2/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuStyle.h"
#import "YLProgressBar.h"

@interface EmuStyle()

@property (nonatomic) NSDictionary *fontsNamesByStyle;

@end

@implementation EmuStyle

#pragma mark - Initialization
// A singleton
+(EmuStyle *)sharedInstance
{
    static EmuStyle *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EmuStyle alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EmuStyle *)sh
{
    return [EmuStyle sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self initFontStyles];
    }
    return self;
}

-(void)initFontStyles
{
    // A mapping from font style name to the font name
    // that should be passed on UIFont initialization.
    self.fontsNamesByStyle = @{
                               @"regular":@"SourceSansPro-Regular",
                               @"bold":@"SourceSansPro-Semibold"
                               };
}

#pragma mark - Fonts
-(NSString *)fontNameForStyle:(NSString *)style
{
    // Use default in nil passed.
    if (style == nil)
        style = @"regular";
    
    // Return corresponding font name or the default if style not found.
    NSString *name = self.fontsNamesByStyle[style];
    return name? name: self.fontsNamesByStyle[@"regular"];
}

-(UIFont *)fontForStyle:(NSString *)style sized:(NSInteger)size
{
    NSString *fontName = [self fontNameForStyle:style];
    return [UIFont fontWithName:fontName size:size];
}

#pragma mark - Colors
-(UIColor *)styleColorNamed:(NSString *)colorName
{
    if ([colorName isEqualToString:@"colorText1"]) {
        return [EmuStyle colorText1];
    } else if ([colorName isEqualToString:@"colorText2"]) {
        return [EmuStyle colorText2];
    }
    return [UIColor blackColor];
}

+(UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(void)styleYLProgressBar:(YLProgressBar *)pb
{
    pb.progressTintColor = [EmuStyle colorButtonBGPositive];
    pb.stripesColor = [[EmuStyle colorButtonBGPositive] colorWithAlphaComponent:0.6];
    pb.trackTintColor = [EmuStyle colorButtonBGNegative];
    pb.stripesAnimated = YES;
}



@end
