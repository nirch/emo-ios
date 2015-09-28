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
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND isFeatured=%@", @YES, @YES];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES]];
    NSArray *packs = [EMDB.sh.context executeFetchRequest:fetchRequest error:nil];
    
    // Get the info about the packs
    NSMutableArray *data = [NSMutableArray new];
    for (Package *pack in packs) {
        NSMutableDictionary *info = [NSMutableDictionary new];
        if (pack.posterName == nil || pack.label == nil) continue;
        
        // Gather the info
        info[@"posterURL"] = pack.urlForPackagePoster;
        info[@"debugLabel"] = pack.label;
        info[@"packOID"] = pack.oid;
        [data addObject:info];
    }
    
    self.featuredData = data;

    // Reload data.
    [self.guiCollectionView reloadData];
    [self fixPage];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
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
    cell.debugLabel = [info[@"debugLabel"] description];
        
    // Update the cell UI
    [cell updateGUI];
    
    return cell;

}

-(NSDictionary *)dataAtCycilcIndex:(NSInteger)cyclicIndex
{
    NSInteger index = cyclicIndex % self.featuredData.count;
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

@end
