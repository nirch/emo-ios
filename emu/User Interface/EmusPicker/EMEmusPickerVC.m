//
//  EMEmusPickerVC.m
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmusPickerVC.h"
#import "EMEmusPickerDataSource.h"
#import "EMUISound.h"
#import "EMDB.h"

@interface EMEmusPickerVC () <
    UICollectionViewDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;


@property (nonatomic) NSDictionary *cfg;
@property (nonatomic) EMEmusPickerDataSource *dataSource;

@end

@implementation EMEmusPickerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUIOnLoad];
    [self initData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Init observers
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

#pragma mark - Initializations
-(void)configureForFavoriteEmus
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite=%@", @YES];
    self.cfg = @{
                 @"predicate":predicate,
                 @"minimumCellsCount":@3,
                 @"sortBy":@[ [NSSortDescriptor sortDescriptorWithKey:@"lastTimeShared" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ],
                 };
}

-(void)configureForRecentlyViewedEmus
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastTimeViewed!=nil"];
    self.cfg = @{
                 @"predicate":predicate,
                 @"minimumCellsCount":@7,
                 @"sortBy":@[ [NSSortDescriptor sortDescriptorWithKey:@"lastTimeViewed" ascending:NO] ],
                 @"limit": @20
                 };
}

-(void)configureForRecentlySharedEmus
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastTimeShared!=nil"];
    self.cfg = @{
                 @"predicate":predicate,
                 @"minimumCellsCount":@7,
                 @"sortBy":@[ [NSSortDescriptor sortDescriptorWithKey:@"lastTimeShared" ascending:NO] ],
                 @"limit": @20
                 };
}

#pragma mark - Initializations
-(void)initGUIOnLoad
{
    //self.guiCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.guiCollectionView.backgroundColor = [UIColor clearColor];
}

-(void)initData
{
    if (self.dataSource == nil) {
        self.dataSource = [[EMEmusPickerDataSource alloc] initWithPredicate:self.cfg[@"predicate"]
                                                                     sortBy:self.cfg[@"sortBy"]
                                                                      limit:self.cfg[@"limit"]
                                                          minimumCellsCount:self.cfg[@"minimumCellsCount"]];
        self.guiCollectionView.dataSource = self.dataSource;
        [self.dataSource resetFRC];
    }
}

#pragma mark - Reload
-(void)refreshLocalData
{
    [self.dataSource resetFRC];
    [self.guiCollectionView reloadData];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // On rendering events.
    [nc addUniqueObserver:self
                 selector:@selector(onEmuStateUpdated:)
                     name:hmkRenderingFinished
                   object:nil];
    
    // Backend downloaded (or failed to download) missing resources for emuticon.
    [nc addUniqueObserver:self
                 selector:@selector(onEmuStateUpdated:)
                     name:hmkDownloadResourceFinished
                   object:nil];
    
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:hmkDownloadResourceFinished];
}

#pragma mark - Observers handlers
-(void)onEmuStateUpdated:(NSNotification *)notification
{
    // Vaidate we have required info
    NSDictionary *info = notification.userInfo;
    if (info == nil) return;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *oid = info[@"emuticonOID"];
    NSString *packageOID = info[@"packageOID"];
    if (indexPath == nil || oid == nil || packageOID == nil) return;
    
    // Check for errors.
    if (notification.isReportingError)
        self.dataSource.failedOIDS[oid] = @YES;
    
    // ignore notifications not relating to emus visible on screen.
    if (![[self.guiCollectionView indexPathsForVisibleItems] containsObject:indexPath]) return;
    
    // Add some checks here that index path is in bounds.
    [self.guiCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
}



#pragma mark - Collection view Layout
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat size = self.view.bounds.size.height;
    return CGSizeMake(size, size);
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    
    NSString *emuOID = [self.dataSource emuticonOIDAtIndexPath:indexPath];
    if (emuOID == nil) return;
    
    NSDictionary *info = @{
                           emkEmuticonOID:emuOID,
                           emkIndexPath:indexPath,
                           emkSender:self.identifier
                           };
    
    [self.delegate controlSentActionNamed:emkUIActionPickedEmu
                                     info:info];
}


#pragma mark - Scrolling
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self handleVisibleCells];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self handleVisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        // Will not decelerate after dragging, so scrolling just ended.
        [self handleVisibleCells];
    }
}

#pragma mark - Handle visible cell
-(void)handleVisibleCells
{
    NSArray *visibleIndexPaths = self.guiCollectionView.indexPathsForVisibleItems;
    [self.dataSource preferEmusAtIndexPaths:visibleIndexPaths];
}

@end
