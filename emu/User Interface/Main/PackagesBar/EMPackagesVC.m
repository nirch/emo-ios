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
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self resetFetchedResultsController];
    
    if (self.selectedPackage == nil)
        [self selectPackageAtIndex:0];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)initGUI
{

}

-(void)refresh
{
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
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
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    
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
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"package cell";
    EMPackageCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(EMPackageCell *)cell forIndexPath:(NSIndexPath *)indexPath
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

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
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

#pragma mark - Scrolling
//-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self updateMoreButtonAnimated:YES];
//}

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
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self selectThisPackage:package];
}

-(void)selectThisPackage:(Package *)package
{
    if (package == nil) return;
    
    self.selectedPackage = package;
    [self.guiCollectionView reloadData];
    [self.delegate packageWasSelected:package];
    
    // Check if selcted package tab is on screen. If not, scroll it into view.
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:package];
    if (indexPath == nil) return;
    if (![self.guiCollectionView.indexPathsForVisibleItems containsObject:indexPath]) {
        [self.guiCollectionView scrollToItemAtIndexPath:indexPath
                                       atScrollPosition:UICollectionViewScrollPositionNone
                                               animated:NO];
    }
}

-(void)selectPackageAtIndex:(NSInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    if (self.fetchedResultsController.fetchedObjects.count<1) return;
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (package == nil) return;
    
    [self selectThisPackage:package];
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

-(BOOL)canSelectPrevious
{
    NSInteger index = [self selectedIndex];
    return index > 0;
}

-(BOOL)canSelectNext
{
    NSInteger index = [self selectedIndex];
    return index < (self.fetchedResultsController.fetchedObjects.count - 1);
}


-(void)selectPrevious
{
    NSInteger index = [self selectedIndex];
    if ([self canSelectPrevious]) {
        index--;
        [self selectPackageAtIndex:index];
    }
}

-(void)selectNext
{
    NSInteger index = [self selectedIndex];
    if ([self canSelectNext]) {
        index++;
        [self selectPackageAtIndex:index];
    }
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
