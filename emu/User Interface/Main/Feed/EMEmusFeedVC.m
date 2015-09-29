//
//  EMEmusFeedVC.m
//  emu
//  -----------------------------------------------------------------------
//  Responsibilities:
//      - Display the emuticon cells in a collection view divided to sections by pack + layout.
//      - (data source logic handled in a seperate object).
//      - Sends notifications about prioritized emus (in visible cells).
//      - Pressing an emu posts a notification that such event happened.
//      - Notifies about "required data fetch".
//      - May notify that a recorder should be opened.
//      - Emus selection UI (+ delegation for other objects that implement retake flow etc).
//      - Handles notifications that requires cells updates.
//  -----------------------------------------------------------------------
//  Created by Aviv Wolf on 9/20/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmusFeedVC.h"
#import "EMNavBarVC.h"
#import "EMNotificationCenter.h"
#import "EMEmusFeedDataSource.h"

#define TAG @"EMEmusFeedVC"

@interface EMEmusFeedVC() <
    UICollectionViewDelegateFlowLayout
>

// The emus feed collection view.
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

// UI initialization
@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;

// The data source.
@property (nonatomic) EMEmusFeedDataSource *dataSource;

@end

@implementation EMEmusFeedVC

#pragma mark - VC lifecycle
/**
 *  On view did load:
 *      - initialize the data source for this VC collection view.
 *      - First, one time initialization of the UI.
 *      - Add the navigation/actions bar.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initDataSource];
    [self initGUIOnLoad];
    [self initNavigationBar];
}

/**
 *  On view appearance:
 *      - Initialize observers.
 *      - Broadcast a notification that a data fetch may be required.
 */
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Init observers
    [self initObservers];
    
    // Refresh data if required
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages object:self userInfo:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HMLOG(TAG, EM_DBG, @"View did appear");
    [self initGUIOnAppearance];
    [self refreshGUIWithLocalData];
    [self.navBarVC bounce];
}

/**
 *  On view will disappear:
 *      - Remove observers
 *
 */
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

#pragma mark - Initializations
/**
 *  Initialized the data source for the collection view of packs.
 */
-(void)initDataSource
{
    // Set the data source.
    self.dataSource = [EMEmusFeedDataSource new];
    self.guiCollectionView.dataSource = self.dataSource;
    [self.dataSource reset];
}


/**
 *  GUI initializations on first loading the UI.
 */
-(void)initGUIOnLoad
{
    self.guiCollectionView.contentInset = UIEdgeInsetsMake(44,0,44,0);
}

-(void)initNavigationBar
{
    EMNavBarVC *navBarVC;
    navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeed]];
    self.navBarVC = navBarVC;
}

/**
 *  Further UI initializations after UI appearance.
 *   - Some initializations will occur only on first appearance.
 *   - Cells layout determind by screen size.
 *   - Add space in layout if featured packs are shown.
 *  Some initializations will happen when screen first appears.
 */
-(void)initGUIOnAppearance
{
    if (!self.alreadyInitializedGUIOnAppearance) {
    }
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
    [self refreshGUIWithLocalData];
}

#pragma mark - Data
-(void)refreshGUIWithLocalData
{
    // Reload the data in the collection view.
    [self.dataSource reset];
    [self.guiCollectionView reloadData];
}

#pragma mark - EMTopVCProtocol
-(void)vcWasSelected
{
    HMLOG(TAG, EM_DBG, @"Top vc selected: EMEmusFeedVC");
}

#pragma mark - Collection view Layout
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat size = (self.view.bounds.size.width-10.0) / 2.0;
    return CGSizeMake(size, size);
}

@end
