//
//  EMPackagesVC.m
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPackagesVC.h"
#import "EMDB.h"
#import "EMPackageCell.h"

@interface EMPackagesVC() <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredBG;
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
    [super viewDidAppear:animated];
    [self resetFetchedResultsController];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)initGUI
{

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
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ];
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
    cell.guiIcon.image = [UIImage imageNamed:package.iconName];
    cell.guiLabel.text = package.label;
    cell.isSelected = [package isEqual:self.selectedPackage];
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width;
    CGFloat height = 58;
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    if (count > 5) {
        width = 98;
    } else {
        width = self.guiCollectionView.bounds.size.width / count;
    }
    return CGSizeMake(width, height);
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
}

-(void)selectPackageAtIndex:(NSInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (package == nil) return;
    
    [self selectThisPackage:package];
}

@end
