//
//  EMAdView.m
//  emu
//
//  Created by Aviv Wolf on 27/04/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMAdView.h"

@interface EMAdView()

@property (weak, nonatomic) IBOutlet UIImageView *guiImage;

@end

@implementation EMAdView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *subView = [[[NSBundle mainBundle] loadNibNamed:@"EMAdView" owner:self options:nil] firstObject];
        subView.frame = self.bounds;
        subView.backgroundColor = [UIColor redColor];
        [self addSubview:subView];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (UILabel *)nativeMainTextLabel
{
    //return self.mainTextLabel;
    return nil;
}

- (UILabel *)nativeTitleTextLabel
{
//    return self.titleLabel;
    return nil;
}

- (UILabel *)nativeCallToActionTextLabel
{
//    return self.callToActionLabel;
    return nil;
}

- (UIImageView *)nativeIconImageView
{
//    return self.iconImageView;
    return nil;
}

- (UIImageView *)nativeMainImageView
{
    return self.guiImage;
}

- (UIImageView *)nativePrivacyInformationIconImageView
{
//    return self.privacyInformationIconImageView;
    return nil;
}

@end
