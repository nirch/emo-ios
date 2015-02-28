//
//  EMAnimatedGifPlayer.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMAnimatedGifPlayer.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface EMAnimatedGifPlayer ()

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimGifView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@end

@implementation EMAnimatedGifPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)setAnimatedGifURL:(NSURL *)animatedGifURL
{
    _animatedGifURL = animatedGifURL;
    
    NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
    FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeCenter;
    
    [self.guiAnimGifView startAnimating];
    [self.guiActivity stopAnimating];
}

-(void)stopAnimating
{
    [self.guiAnimGifView stopAnimating];
}

-(void)startActivity
{
    [self.guiActivity startAnimating];
}

@end
