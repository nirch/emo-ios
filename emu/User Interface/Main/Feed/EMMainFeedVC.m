//
//  EMMainFeedVC.m
//  emu
//
//  Created by Aviv Wolf on 6/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMMainFeedVC"

#import "EMMainFeedVC.h"
#import "EMNotificationCenter.h"
#import "EMFeedDataSource.h"

@interface EMMainFeedVC () <
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>

@property (weak, nonatomic) IBOutlet UIView *guiNavBar;
@property (strong, nonatomic) IBOutlet EMFeedDataSource *guiDataSource;
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

@property (nonatomic) CGFloat emuCellSize;

@end

@implementation EMMainFeedVC

#pragma mark - VC Lifecycle

//
// When view is first loaded, will show a slpash screen.
//
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
    [self showSplashAnimated:NO];
}

//
// When the view is about to appear, will notify
// the backend about it. The back end will decide if the app's data should be
// refreshed or not.
// Will show an activity until the backend decides not to refresh or finishes
// updating the data from the server.
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Give the data source a weak pointer to the collection view
    self.guiDataSource.collectionView = self.guiCollectionView;
    
    // Refresh data if required
    [self showWaitingForDataRefresh];
    [self.guiDataSource refreshData];
}

//
// Recalculate the layout when layout changes should be made.
-(void)viewDidLayoutSubviews
{
    [self recalcLayout];
}


#pragma mark - Initializations
-(void)initGUI
{
    UIEdgeInsets insets = UIEdgeInsetsMake(8, 0, 50, 0);
    self.guiCollectionView.contentInset = insets;
}


#pragma mark - Splash screen & waiting for first data UI
-(void)showSplashAnimated:(BOOL)animated
{
    
}

-(void)showWaitingForDataRefresh
{
    
}

#pragma mark - VC preferences
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout
-(void)recalcLayout
{
    self.emuCellSize = (self.view.bounds.size.width-10.0) / 6.0;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.emuCellSize, self.emuCellSize);
}


#pragma mark - Cells on screen checks
-(void)checkCellsOnScreen
{
    //NSArray *cellsOnScreen = self.guiCollectionView.indexPathsForVisibleItems;
    //HMLOG(TAG, EM_DBG, @"Cells on screen: %@", cellsOnScreen);
}

#pragma mark - ScrollViewDelegate
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self checkCellsOnScreen];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDebugButton:(id)sender
{
    [self.guiDataSource reloadLocalData];
    [self.guiCollectionView reloadData];
}


@end
