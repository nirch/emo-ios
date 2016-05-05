//
//  EMFeaturedVC.m
//  emu
//
//  Created by Aviv Wolf on 9/20/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFeaturedVC.h"
#import "EMFeaturedCell.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"
#import "EMUINotifications.h"
#import <PINRemoteImageManager.h>

#define FEATURED_ASPECT_RATIO 1.75f
#define CYCLYC_COUNT 20

@interface EMFeaturedVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;


@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGFloat marginForCentering;
@property (nonatomic) CGFloat featuredCellHeight;

@property (nonatomic) NSArray *featuredData;

@property (nonatomic) NSTimer *flippingTimer;
@property (nonatomic) BOOL ignoreAutoFlipping;

@end

@implementation EMFeaturedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.guiCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Init observers
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startAutoFlipping];

    // Cells layout settings
    CGFloat cellHeight = self.guiCollectionView.bounds.size.height;
    CGFloat cellWidth = cellHeight*FEATURED_ASPECT_RATIO;
    self.cellSize = CGSizeMake(cellWidth, cellHeight);
    self.marginForCentering = (self.guiCollectionView.bounds.size.width - cellWidth) / 2.0f;
    [self refreshUIWithLocalData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopAutoFlipping];
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onUpdatedData:)
                     name:emkDataUpdatedPackages
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataUpdatedPackages];
}

#pragma mark - Auto Flipping
-(void)startAutoFlipping
{
    [self.flippingTimer invalidate];
//    self.flippingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
//                                                          target:self
//                                                        selector:@selector(onFlipRequired:)
//                                                        userInfo:nil repeats:YES];
}

-(void)stopAutoFlipping
{
    [self.flippingTimer invalidate];
    self.flippingTimer = nil;
}

-(void)onFlipRequired:(NSTimer *)timer
{
    if (self.ignoreAutoFlipping) return;
    if (self.featuredData.count == 0) return;
    
    NSInteger page = [self currentPage];
    page = [self boundPageIndex:page+1];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:page inSection:0];
    if (indexPath == nil) return;
    
    [UIView animateWithDuration:0.7
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         if (indexPath == nil) return;
                         [self.guiCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                     } completion:^(BOOL finished) {
                         [self fixPage];
                     }];
}

#pragma mark - Observers handlers
-(void)onUpdatedData:(NSNotification *)notification
{
    [self refreshUIWithLocalData];
}


#pragma mark - Data
-(void)refreshUIWithLocalData
{
    // Initialize the data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND isFeatured=%@ AND (isHidden=nil OR isHidden=%@)", @YES, @YES, @NO];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES]];
    NSArray *packs = [EMDB.sh.context executeFetchRequest:fetchRequest error:nil];
    
    // Get the info about the packs
    NSMutableArray *data = [NSMutableArray new];
    for (Package *pack in packs) {
        if (pack.posterName == nil || pack.label == nil) continue;
        
        // Gather the info
        HMParams *params = [HMParams new];
        [params addKey:@"posterURL" valueIfNotNil:[pack urlForPackagePoster]];
        [params addKey:@"thumbForAnimatedPosterURL" valueIfNotNil:[pack urlForAnimatedPosterThumb]];
        [params addKey:@"posterOverlayURL" valueIfNotNil:[pack urlForPackagePosterOverlay]];
        [params addKey:@"debugLabel" valueIfNotNil:[pack urlForPackagePoster]];
        [params addKey:@"packOID" valueIfNotNil:pack.oid];
        [params addKey:@"packLabel" valueIfNotNil:pack.label];
        [params addKey:@"packName" valueIfNotNil:pack.name];
        [data addObject:params.dictionary];
    }
    
    self.featuredData = data;

    // Prefetch thumbs
    [self prefetchThumbs];
    
    // Reload data.
    [self.guiCollectionView reloadData];
    [self fixPage];
}

-(void)prefetchThumbs
{
    NSMutableArray *thumbs = [NSMutableArray new];
    PINRemoteImageManager *pinRemoteManager = [PINRemoteImageManager sharedImageManager];
    for (NSDictionary *packInfo in self.featuredData) {
        if (packInfo[@"thumbForAnimatedPosterURL"] == nil) continue;
        NSURL *thumbURL = packInfo[@"thumbForAnimatedPosterURL"];
        if (thumbURL) [thumbs addObject:thumbURL];
    }
    [pinRemoteManager prefetchImagesWithURLs:thumbs];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.featuredData.count*CYCLYC_COUNT;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"featured cell";
    EMFeaturedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                     forIndexPath:indexPath];
    // Get the info
    NSDictionary *info = [self dataAtCycilcIndex:indexPath.item];
    
    // Configure the cell using info about the pack
    cell.posterURL = info[@"posterURL"];
    cell.animatedPosterThumbURL = info[@"thumbForAnimatedPosterURL"];
    cell.posterOverlayURL = info[@"posterOverlayURL"];
    cell.debugLabel = [info[@"debugLabel"] description];
    cell.label = info[@"packLabel"];
    cell.name = info[@"packName"];
        
    // Update the cell UI
    [cell updateGUI];
    
    return cell;

}

-(NSInteger)cyclicIndex:(NSInteger)index
{
    return index % self.featuredData.count;
}

-(NSDictionary *)dataAtCycilcIndex:(NSInteger)cyclicIndex
{
    NSInteger index = [self cyclicIndex:cyclicIndex];
    return self.featuredData[index];
}

#pragma mark - Collection view layout
/**
 *  Determine the required layout for a cell in a given index path.
 *
 *  @param collectionView       The related collection view.
 *  @param collectionViewLayout The layout.
 *  @param indexPath            Index path of the cel.
 *
 *  @return CGSize required for the cell.
 */
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellSize;
}

#pragma mark - Scrolling
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                    withVelocity:(CGPoint)velocity
             targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat position = targetContentOffset->x + scrollView.bounds.size.width/2.0f;
    NSInteger page = [self pageIndexAtPosition:position];
    *targetContentOffset = [self offsetForPage:page];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self fixPage];
    [self startAutoFlipping];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self stopAutoFlipping];
}

#pragma mark - Paging
-(void)fixPage
{
    if (self.featuredData.count==0) return;
    
    NSInteger page = [self currentPage];
    NSInteger size = self.featuredData.count;
    page = page % size + size * (CYCLYC_COUNT/2);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:page inSection:0];
    [self.guiCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    self.ignoreAutoFlipping = NO;
}

-(NSInteger)currentPage
{
    NSInteger page = [self pageIndexAtPosition:self.guiCollectionView.contentOffset.x+self.guiCollectionView.bounds.size.width/2.0f];
    return [self boundPageIndex:page];
}

-(NSInteger)pageIndexAtPosition:(CGFloat)position
{
    NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:CGPointMake(position, 0)];
    return [self boundPageIndex:indexPath.item];
}

-(NSInteger)boundPageIndex:(NSInteger)page
{
    page = MAX(0,page);
    page = MIN(self.featuredData.count*CYCLYC_COUNT-1,page);
    return page;
}

-(CGPoint)offsetForPage:(NSInteger)page
{
    CGPoint offset = CGPointMake(page*self.cellSize.width-self.marginForCentering, 0);
    return offset;
}

#pragma mark - Selection
-(void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *info = [self dataAtCycilcIndex:indexPath.item];
    NSString *packageOID = info[@"packOID"];
    if (packageOID == nil) return;
    
    self.guiCollectionView.userInteractionEnabled = NO;
    dispatch_after(DTIME(0.3), dispatch_get_main_queue(), ^{
        self.guiCollectionView.userInteractionEnabled = YES;
        // Notify that a pack was selected.
        NSDictionary *info = @{emkPackageOID:packageOID};
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserSelectedPack
                                                            object:self
                                                          userInfo:info];
    });
}

@end
