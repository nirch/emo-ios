//
//  EMAnimatedGifPlayer.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMAnimatedGifPlayer : UIViewController

@property (nonatomic) NSURL *animatedGifURL;
@property (nonatomic) BOOL locked;

-(void)setAnimatedGifNamed:(NSString *)gifName;
-(void)startActivity;
-(void)stopAnimating;

@end
