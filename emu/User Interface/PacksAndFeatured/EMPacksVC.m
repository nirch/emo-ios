//
//  EMFeaturedVC.m
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPacksVC.h"
#import "EMPackCell.h"
#import "EMNavBarVC.h"

#define PACKS_CELLS_ASPECT_RATIO 3.6f
#define PACKS_PADDING_H 12.0f

@interface EMPacksVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiFeaturedPacksContainer;

@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (nonatomic, readwrite) BOOL featuredPacksShown;

@property (nonatomic) CGFloat packCellHeight;
@property (nonatomic) CGFloat packCellWidth;
@property (nonatomic) CGFloat packsTopPosition;

@property (nonatomic) NSInteger packsCount;
@property (nonatomic) NSInteger lastWidePack;

@end

@implementation EMPacksVC

+(EMPacksVC *)packsVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PacksAndFeatured" bundle:nil];
    EMPacksVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"featured vc"];
    vc.featuredPacksShown = NO;
    return vc;
}

+(EMPacksVC *)packsVCWithFeaturedPacks
{
    EMPacksVC *vc = [EMPacksVC packsVC];
    vc.featuredPacksShown = YES;
    return vc;
}

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.guiCollectionView.backgroundColor = [UIColor clearColor];
    self.guiCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    
    EMNavBarVC *navBarVC;
    if (self.featuredPacksShown) {
        navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeatured]];
    } else {
        navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeed]];
    }
    self.navBarVC = navBarVC;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUI];
}


#pragma mark - Initializations
-(void)initGUI
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGSize size = screenRect.size;
    
    // Cells settings
    self.packCellWidth = (CGFloat)(int)(size.width/2 - PACKS_PADDING_H) ;
    self.packCellHeight = (CGFloat)(int)self.packCellWidth / PACKS_CELLS_ASPECT_RATIO;
    
    // Collection view settings
    CGRect f = self.guiFeaturedPacksContainer.frame;
    if (self.featuredPacksShown) {
        self.packsTopPosition = f.origin.y + f.size.height + 6;
        self.guiFeaturedPacksContainer.hidden = NO;
    } else {
        self.packsTopPosition = f.origin.y + 6;
        self.guiFeaturedPacksContainer.hidden = YES;
    }
    
    // Reload the data in the collection view.
    [self.guiCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    self.packsCount = 299;
    self.lastWidePack = (self.packsCount%2==0)?2:3;
    return self.packsCount;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"pack cell";
    EMPackCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                            forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(EMPackCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    
}



#pragma mark - Collection view layout
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldBeWideButton = indexPath.item < self.lastWidePack;
    
    if (shouldBeWideButton) {
        return CGSizeMake(self.packCellWidth * 2, self.packCellHeight);
    } else {
        return CGSizeMake(self.packCellWidth, self.packCellHeight);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(self.packsTopPosition, PACKS_PADDING_H, 0, PACKS_PADDING_H);
}


#pragma mark - Scrolling
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat scale = 1.0f;
    if (offset >= 0) {
        if (!CGAffineTransformIsIdentity(self.guiFeaturedPacksContainer.transform))
            self.guiFeaturedPacksContainer.transform = CGAffineTransformIdentity;
    } else {
        offset = offset / 5.0f;
        scale += fabs(offset) / 100.0f;
    }
    
    CGAffineTransform t = CGAffineTransformMakeTranslation(0, -offset);
    if (scale > 1.0f) t = CGAffineTransformScale(t, scale, scale);
    self.guiFeaturedPacksContainer.transform = t;
}


@end
