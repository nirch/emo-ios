//
//  EMExperimentalVC.m
//  emu
//
//  Created by Aviv Wolf on 2/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMExperimentalVC.h"

#import "EMExperimentalCell.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@interface EMExperimentalVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate
>

@end

@implementation EMExperimentalVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1500;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    EMExperimentalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                         forIndexPath:indexPath];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:[SF:@"%@", @(indexPath.item % 9+1)] withExtension:@"gif"];
    NSData *animGifData = [NSData dataWithContentsOfURL:url];
    FLAnimatedImage *animGif = [FLAnimatedImage animatedImageWithGIFData:animGifData];
    cell.guiAnimGifView.animatedImage = animGif;
    
    return cell;
}

@end
