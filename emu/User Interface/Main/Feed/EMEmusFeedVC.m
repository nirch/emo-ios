//
//  EMEmusFeedVC.m
//  emu
//  -----------------------------------------------------------------------
//  Responsibilities:
//      - Display the emuticon cells in a collection view divided to sections by pack + layout.
//      - Owns and uses data source object.
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
#import "EMNavBarDelegate.h"
#import "EMCustomPopoverVC.h"
#import "EMPacksVC.h"
#import "EMUINotifications.h"
#import "EMDB.h"

#define TAG @"EMEmusFeedVC"

@interface EMEmusFeedVC() <
    UICollectionViewDelegateFlowLayout,
    EMNavBarDelegate
>

// The emus feed collection view.
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

// UI initialization
@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (weak, nonatomic) EMCustomPopoverVC *popoverController;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;

// The data source.
@property (nonatomic) EMEmusFeedDataSource *dataSource;

// Current top section
@property (nonatomic) NSInteger currentTopSection;

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
    self.navBarVC.delegate = self;
    self.navBarVC.configurationSource = self;
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
        [self setCurrentTopSection:0];
        self.alreadyInitializedGUIOnAppearance = YES;
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
    
    // On user selected a pack
    [nc addUniqueObserver:self
                 selector:@selector(onUserSelectedAPack:)
                     name:emkUIUserSelectedPack
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataUpdatedPackages];
    [nc removeObserver:emkUIUserSelectedPack];
}

#pragma mark - Observers handlers
-(void)onUpdatedData:(NSNotification *)notification
{
    [self refreshGUIWithLocalData];
}

-(void)onUserSelectedAPack:(NSNotification *)notification
{
    // User pressed a pack in the packs popover.
    // Dismiss the popover and scroll to the selected pack.
    NSString *packOID = notification.userInfo[emkOID];
    __weak EMEmusFeedVC *weakSelf = self;
    [self.popoverController dismissViewControllerAnimated:YES completion:^{
        if (packOID == nil) return;
        NSIndexPath *indexPath = [weakSelf.dataSource indexPathForPackOID:packOID];
        if (indexPath == nil) return;
        [self scrollToSection:indexPath.section animated:NO];
    }];
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

-(void)setCurrentTopSection:(NSInteger)currentTopSection
{
    _currentTopSection = currentTopSection;
    NSString *titleForSection = [self.dataSource titleForSection:_currentTopSection];
    titleForSection = [SF:@"%@ ▼", titleForSection];
    [self.navBarVC updateTitle:titleForSection];
}

#pragma mark - Scrolling
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    offset.y += scrollView.contentInset.top;
    [self.navBarVC childVCDidScrollToOffset:offset];
    
    NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:CGPointMake(self.guiCollectionView.center.x, 52+scrollView.contentOffset.y)];
    if (indexPath && self.currentTopSection != indexPath.section) {
        // Top section changed.
        self.currentTopSection = indexPath.section;
    }
}

-(void)scrollToSection:(NSInteger)sectionIndex animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
    [self.guiCollectionView scrollToItemAtIndexPath:indexPath
                                   atScrollPosition:UICollectionViewScrollPositionTop
                                           animated:animated];
}

#pragma mark - Packs list popover
-(void)showPacksListAsPopOver:(UIControl *)control
{
    EMCustomPopoverVC *popoverController;
    popoverController = [[EMCustomPopoverVC alloc] init];
    popoverController.popoverPresentationController.sourceView = control.superview; //The view containing the anchor rectangle for the popover.
    popoverController.popoverPresentationController.sourceRect = control.frame; //The rectangle in the specified view in which to anchor the popover.
    [self presentViewController:popoverController animated:YES completion:nil];
    
    NSString *topPackOID = [self.dataSource packOIDForSection:self.currentTopSection];
    EMPacksVC *packsVC = [EMPacksVC packsVC];
    [popoverController addChildViewController:packsVC];
    [popoverController.view addSubview:packsVC.view];

    // Highlight a pack
    [packsVC highlightPackWithOID:topPackOID];
    
    // Store a weak reference to the popover
    self.popoverController = popoverController;
}

#pragma mark - EMNavBarDelegate
-(void)navBarOnTitleButtonPressed:(UIButton *)sender
{
    [self showPacksListAsPopOver:sender];
}

-(void)navBarOnUserActionNamed:(NSString *)actionName
                        sender:(id)sender
                         state:(NSInteger)state
                          info:(NSDictionary *)info
{
    
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedPackSectionButton:(UIButton *)sender
{
    NSInteger sectionIndex = sender.tag;
    
    // Ensure section index is in bounds.
    if (sectionIndex>0 && sectionIndex<[self.dataSource packsCount]) {
        [self scrollToSection:sectionIndex animated:YES];
    }
}


@end
