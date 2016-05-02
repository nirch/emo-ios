//
//  EMSimpleBannerAdView.h
//  emu
//
//  Created by Aviv Wolf on 01/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MPAdView.h>

@interface EMSimpleBannerAdView : UIView

@property (nonatomic) NSString *adPlacementKey;

-(void)refresh;
-(void)setBannerDelegate:(id<MPAdViewDelegate>)delegate;

@end
