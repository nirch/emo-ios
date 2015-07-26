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
#import "EMCaches.h"

@interface EMAnimatedGifPlayer ()

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *guiAnimGifView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIImageView *guiLock;

@end

@implementation EMAnimatedGifPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locked = NO;
}

-(void)setAnimatedGifURL:(NSURL *)animatedGifURL
{
    _animatedGifURL = animatedGifURL;
    
    NSData *animGifData = [NSData dataWithContentsOfURL:animatedGifURL];
    FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
    
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

-(void)setLocked:(BOOL)locked
{
    self.guiLock.alpha = locked? 0.2:0.0;
}

-(void)setAnimatedGifNamed:(NSString *)gifName
{
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:gifName withExtension:@"gif"];
    FLAnimatedImage *animGif = [EMCaches.sh.gifsDataCache objectForKey:gifURL];
    if (animGif == nil) {
        NSData *animGifData = [NSData dataWithContentsOfURL:gifURL];
        animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
        [EMCaches.sh.gifsDataCache setObject:animGif forKey:[gifURL description]];
    }
    self.guiAnimGifView.animatedImage = animGif;
    self.guiAnimGifView.contentMode = UIViewContentModeScaleAspectFit;
}

@end
