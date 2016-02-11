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
@property (weak, nonatomic) IBOutlet UILabel *guiPlaceHolderLabel;


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

    [self checkIfNeedToDisplayPlaceHolderImage];
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
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        [self handleVisibleCells];
        [self checkIfNeedToDisplayPlaceHolderImage];
    });
}

-(void)checkIfNeedToDisplayPlaceHolderImage
{
    if (self.dataSource.emusCount == 0) {
        if (self.placeHolderMessageWhenEmpty != nil) {
            self.guiPlaceHolderLabel.hidden = NO;
            self.guiPlaceHolderLabel.text = self.placeHolderMessageWhenEmpty;
            self.guiCollectionView.alpha = 0;
        }
    } else {
        self.guiPlaceHolderLabel.hidden = YES;
        self.guiCollectionView.alpha = 1;
    }

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
    NSIndexPath *indexPath = info[emkIndexPath];
    NSString *oid = info[emkEmuticonOID];
    NSString *packageOID = info[emkPackageOID];
    if (indexPath == nil || oid == nil || packageOID == nil) return;
    
    // Check for errors.
    if (notification.isReportingError) {
        self.dataSource.failedOIDS[oid] = @YES;
    }
    
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
    CGFloat aspectRatio = [self.dataSource aspectRatioAtIndexPath:indexPath];
    CGFloat height = self.view.bounds.size.height;
    CGFloat width = height*aspectRatio;
    return CGSizeMake(width, height);
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    
    NSString *emuOID = [self.dataSource emuticonOIDAtIndexPath:indexPath];
    if (emuOID == nil) return;
    
    if (self.dataSource.failedOIDS[emuOID]) {
        [self.dataSource.failedOIDS removeAllObjects];
        [self refreshLocalData];
        return;
    }

    
    NSDictionary *info = @{
                           emkEmuticonOID:emuOID,
                           emkIndexPath:indexPath,
                           emkSender:self.identifier
                           };
    
    // Analytics
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emu.emuDef.name];
    [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emu.emuDef.oid];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emu.emuDef.package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emu.emuDef.package.oid];
    [params addKey:AK_EP_ORIGIN_UI value:self.identifier];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_SELECTED_ITEM info:params.dictionary];

    
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
