//
//  EMPackagesVC.m
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMPackagesVC"

#import "EMPackagesVC.h"
#import "EMDB.h"
#import "EMPackageCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface EMPackagesVC() <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredBG;
@property (weak, nonatomic) IBOutlet UIView *guiMoreContainer;
@property (nonatomic) Package *selectedPackage;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) BOOL effectsAlreadySet;

@end

@implementation EMPackagesVC

@synthesize fetchedResultsController = _fetchedResultsController;

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.effectsAlreadySet = NO;
    self.guiCollectionView.contentInset = UIEdgeInsetsZero;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resetFetchedResultsController];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)dealloc
{
    self.guiCollectionView.delegate = nil;
    self.guiCollectionView.dataSource = nil;
}

#pragma mark - Initialization & refresh
-(void)initGUI
{

}

-(void)refresh
{
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
    [self updateMoreButtonAnimated:YES];
}

-(BOOL)isEmpty
{
    return self.fetchedResultsController.fetchedObjects.count < 1;
}

-(void)setupEffects
{
    if (self.effectsAlreadySet) return;
    
    //
    // Add blur effect to the background.
    //
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.guiBlurredBG.bounds;
    [self.guiBlurredBG addSubview:visualEffectView];
    
    self.effectsAlreadySet = YES;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupEffects];
}

#pragma mark - Fetched results controller
-(NSFetchedResultsController *)fetchedResultsController
{
    if ([self.delegate respondsToSelector:@selector(packagesDataIsNotAvailable)]) {
        // Some delegates can decide to lock reading the data for awhile.
        if ([self.delegate packagesDataIsNotAvailable]) {
            return nil;
        }
    }
    
    // Return the fetched results controller
    // (create it if instance not available yet)
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate;
    if (self.onlyRenderedPackages) {
        predicate = [NSPredicate predicateWithFormat:@"showOnPacksBar=%@ AND rendersCount>%@ AND isActive=%@", @YES, @0, @YES];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"showOnPacksBar=%@ AND isActive=%@", @YES, @YES];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Root"];
    _fetchedResultsController = frc;
    return frc;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    [self.delegate packagesAvailableCount:count];
    if (count==0) return 0;
    
    if (self.showMixedPackage) {
        return count+1;
    } else {
        return count;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *packCellIdentifier = @"package cell";
    static NSString *mixedPackCellIdentifier = @"mixed package cell";
    EMPackageCell *cell;
    
    if (self.showMixedPackage && indexPath.item == 0) {
        cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:mixedPackCellIdentifier forIndexPath:indexPath];
    } else {
        cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:packCellIdentifier forIndexPath:indexPath];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(EMPackageCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    if (self.showMixedPackage) {
        if (indexPath.item == 0) {
            [self _configureCellForMixedPack:cell];
        } else {
            NSIndexPath *indexPathForPack = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:0];
            [self _configureCell:cell forIndexPath:indexPathForPack];
        }
        return;
    }
    
    [self _configureCell:cell forIndexPath:indexPath];
}

-(void)_configureCell:(EMPackageCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.guiLabel.text = package.label;
    cell.isSelected = [package isEqual:self.selectedPackage];
    
    NSURL *url = [package urlForPackageIcon];
    [cell.guiIcon sd_setImageWithURL:url
                    placeholderImage:nil
                             options:SDWebImageRetryFailed|SDWebImageHighPriority
                           completed:nil];
}

-(void)_configureCellForMixedPack:(EMPackageCell *)cell
{
    cell.guiIcon.image = [UIImage imageNamed:@"mixed_icon"];
    cell.isSelected = self.selectedPackage == nil;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cellSizeByHeight) {
        CGFloat height = collectionView.bounds.size.height;
        CGFloat width = height;
        return CGSizeMake(width, height);
    } else {
        CGFloat width;
        CGFloat height = 58;
        NSInteger count = self.fetchedResultsController.fetchedObjects.count;
        if (count > 5) {
            width = 70;
        } else {
            width = self.guiCollectionView.bounds.size.width / count;
        }
        return CGSizeMake(width, height);
    }
}

#pragma mark - Scrolling
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateMoreButtonAnimated:YES];
}

#pragma mark - More button
-(void)updateMoreButtonAnimated:(BOOL)animated
{
    if ([self moreToShow]) {
        [self showMoreButtonAnimated:animated];
    } else {
        [self hideMoreButtonAnimated:animated];
    }
}

-(BOOL)moreToShow
{
    CGFloat width = self.guiCollectionView.contentSize.width;
    CGFloat x = self.guiCollectionView.contentOffset.x + self.guiCollectionView.bounds.size.width;
    return x < width - 10;
}

-(void)showMoreButtonAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showMoreButtonAnimated:NO];
        }];
        return;
    }
    
    self.guiMoreContainer.alpha = 1;
}

-(void)hideMoreButtonAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self hideMoreButtonAnimated:NO];
        }];
        return;
    }
    
    self.guiMoreContainer.alpha = 0;
}

#pragma mark - Collection View Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showMixedPackage) {
        if (indexPath.item == 0) {
            [self selectThisPackage:nil];
            return;
        } else {
            indexPath = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:0];
        }
    }
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self selectThisPackage:package];
}

-(void)selectThisPackage:(Package *)package
{
    [self selectThisPackage:package highlightOnly:NO];
}

-(void)selectThisPackage:(Package *)package highlightOnly:(BOOL)highlightOnly
{
    self.selectedPackage = package;
    [self.guiCollectionView reloadData];
    
    if (!highlightOnly) {
        [self.delegate packageWasSelected:package];
    }
    
    // Check if selcted package tab is on screen. If not, scroll it into view.
    NSIndexPath *indexPath;
    if (package) {
        indexPath = [self.fetchedResultsController indexPathForObject:package];
        if (self.showMixedPackage && indexPath.item > 0) {
            indexPath = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
        }
    } else {
        indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    if (indexPath == nil) return;
    
    [self.guiCollectionView scrollToItemAtIndexPath:indexPath
                                   atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                           animated:YES];
}

-(void)selectPackageAtIndex:(NSInteger)index
{
    [self selectPackageAtIndex:index highlightOnly:NO];
}

-(void)selectPackageAtIndex:(NSInteger)index highlightOnly:(BOOL)highlightOnly
{
    if (self.fetchedResultsController.fetchedObjects.count<1 || index<0) {
        [self selectThisPackage:nil highlightOnly:highlightOnly];
        [self.guiCollectionView setContentOffset:CGPointZero animated:NO];
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self selectThisPackage:package highlightOnly:highlightOnly];
}

-(NSInteger)selectedIndex
{
    if (self.selectedPackage) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:self.selectedPackage];
        if (indexPath == nil) return -1;
        return indexPath.item;
    }
    return -1;
}


/**
 *  Select the previous pack (cyclical)
 */
-(void)selectPrevious
{
    NSInteger index = [self selectedIndex];
    index--;
    if (index<-1) index=self.fetchedResultsController.fetchedObjects.count-1;
    [self selectPackageAtIndex:index];
}

/**
 *  Select the next pack (cyclical)
 */
-(void)selectNext
{
    NSInteger index = [self selectedIndex];
    index++;
    if (index>=self.fetchedResultsController.fetchedObjects.count) index=-1;
    [self selectPackageAtIndex:index];
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedMoreButton:(UIButton *)sender
{
    CGFloat width = self.guiCollectionView.contentSize.width;
    CGFloat height = self.guiCollectionView.contentSize.height;

    CGFloat x = self.guiCollectionView.contentOffset.x;
    x += 1;
    
    CGRect rect = CGRectMake(x, 0, width, height);
    [self.guiCollectionView scrollRectToVisible:rect animated:YES];
}


@end
