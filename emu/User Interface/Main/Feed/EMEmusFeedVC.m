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
//
//      - REFACTOR: Shows / hides the selection actions bar with animation and stuff????!?!?
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
#import "EMEmusFeedNavigationCFG.h"
#import "EMEmuCell.h"
#import "EMUISound.h"
#import "EMFeedSelectionsActionBarVC.h"


#define TAG @"EMEmusFeedVC"

@interface EMEmusFeedVC() <
    UICollectionViewDelegateFlowLayout,
    EMNavBarDelegate,
    UIGestureRecognizerDelegate
>

// The emus feed collection view.
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

// UI initialization
@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (weak, nonatomic) EMCustomPopoverVC *popoverController;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;

// Selection actions bar
@property (weak, nonatomic) IBOutlet UIView *guiSelectionActionsBar;
@property (weak, nonatomic) EMFeedSelectionsActionBarVC *selectionsActionBarVC;

// The data source.
@property (nonatomic) EMEmusFeedDataSource *dataSource;

// Current top section
@property (nonatomic) NSInteger currentTopSection;

@end

@implementation EMEmusFeedVC

@synthesize currentState = _currentState;

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
    [self initState];
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


/**
 *  More initialization and state checks on appearance.
 */
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

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selection bar segue"]) {
        self.selectionsActionBarVC = segue.destinationViewController;
    }
}

#pragma mark - Initializations
/**
 *  Initialize the feed to the browsing / normal state.
 */
-(void)initState
{
    [self updateState:EMEmusFeedStateBrowsing info:nil];
}

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
    [self hideSelectionsActionBarAnimated:NO];
    self.guiCollectionView.contentInset = UIEdgeInsetsMake(44,0,44,0);
    
    // Long press gesture recognizer on cells.
    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    longpressGesture.minimumPressDuration = 0.8;
    longpressGesture.delegate = self;
    [self.guiCollectionView addGestureRecognizer:longpressGesture];
}

/**
 *
 */
-(void)initNavigationBar
{
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeed]];
    self.navBarVC.delegate = self;
    
    self.navBarCFG = [EMEmusFeedNavigationCFG new];
    self.navBarVC.configurationSource = self.navBarCFG;
    [self.navBarVC updateUIByCurrentState];
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

#pragma mark - State
-(void)updateState:(NSInteger)newState info:(NSDictionary *)info
{
    // The feed state machine.
    if (self.currentState == 0 && newState == EMEmusFeedStateBrowsing) {
        // =======================================
        // undefined ==> EMEmusFeedStateSelecting
        // =======================================
        // initialization only. No actions. Must start in the browsing state.
        _currentState = newState;

    } else if (self.currentState == EMEmusFeedStateBrowsing && newState == EMEmusFeedStateSelecting) {
        // =====================================================
        // EMEmusFeedStateBrowsing ==> EMEmusFeedStateSelecting
        // =====================================================
        // Changing from the browsing state to the emus selection state
        _currentState = newState;
        NSIndexPath *indexPath = info[@"indexPath"];
        [self _startSelectingEmusWithIndexPath:indexPath];

    } else if (self.currentState == EMEmusFeedStateSelecting && newState == EMEmusFeedStateBrowsing) {
        // =====================================================
        // EMEmusFeedStateSelecting ==> EMEmusFeedStateBrowsing
        // =====================================================
        // Changing from the browsing state to the emus selection state
        _currentState = newState;
        [self _stopSelectingEmus];

    } else {
        // Explode on test application,
        // ignore action silently on production app (after remote logging this)
        REMOTE_LOG(@"Feed on wrong state %@ for new state %@", @(self.currentState), @(newState));
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{
                                                        @"oldState":@(self.currentState),
                                                        @"newState":@(newState)
                                                        }];
    }
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

#pragma mark - Collection View Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];

    if (self.currentState == EMEmusFeedStateBrowsing) {
        // When browsing, selection of an emu will navigate to the emu screen.
        return;
    } else if (self.currentState == EMEmusFeedStateSelecting) {
        // When on selection state, will select/unselect the emu when tapping an emu.
        [self.dataSource toggleSelectionForEmuAtIndexPath:indexPath];
        [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
        [self.guiCollectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
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
    if ([actionName isEqualToString:EMK_NAV_ACTION_SELECT]) {
        
        // Change to the selection state.
        [self updateState:EMEmusFeedStateSelecting info:nil];
        [self.navBarVC updateUIByCurrentState];
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_RETAKE]) {
        
        // Show the retake options
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_CANCEL_SELECTION]) {
        
        // Do nothing and change back to the
        [self updateState:EMEmusFeedStateBrowsing info:nil];
        [self.navBarVC updateUIByCurrentState];
        //[self.footagesBar hideAnimated:YES];
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_SELECT_PACK]) {
        
        [self _toggleTopPackSelection];
        
    }
}

#pragma mark - Selections action bar
/**
 *  Show the selections action bar.
 *
 *  @param animated BOOL indicating if to reveal with an animation or not.
 */
-(void)showSelectionsActionBarAnimated:(BOOL)animated
{
    if (animated) {
        // Slide in the action bar from the bottom of the screen.
        self.guiSelectionActionsBar.hidden = NO;
        CGFloat height = self.guiSelectionActionsBar.bounds.size.height;
        self.guiSelectionActionsBar.transform = CGAffineTransformMakeTranslation(0, height);
        [UIView animateWithDuration:0.2 animations:^{
            self.guiSelectionActionsBar.transform = CGAffineTransformIdentity;
        }];
    } else {
        // Just show it.
        self.guiSelectionActionsBar.hidden = NO;
        self.guiSelectionActionsBar.transform = CGAffineTransformIdentity;
    }
    
    // Also post a notification that the tabs bar (if shown) should be hidden.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldHideTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@(animated)}];
}

/**
 *  Hide the selections action bar.
 *
 *  @param animated BOOL indicating if to hide with an animation or not.
 */
-(void)hideSelectionsActionBarAnimated:(BOOL)animated
{
    if (animated) {
        // Slide out the action bar below the bottom of the screen.
        CGFloat height = self.guiSelectionActionsBar.bounds.size.height;
        [UIView animateWithDuration:0.2 animations:^{
            self.guiSelectionActionsBar.transform = CGAffineTransformMakeTranslation(0, height);
        } completion:^(BOOL finished) {
            self.guiSelectionActionsBar.hidden = YES;
        }];
    } else {
        // Just hide it.
        self.guiSelectionActionsBar.hidden = YES;
    }
    
    // Also post a notification that the tabs bar (if hidden) should be shown.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@(animated)}];

}

#pragma mark - Selecting emus
// Important remark - Never call methods with the _ prefix outside of the vc state machine.

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_startSelectingEmusWithIndexPath:(NSIndexPath *)indexPath
{
    [self.dataSource enableSelections];
    [self.dataSource clearSelections];
    if (indexPath) [self.dataSource selectEmuAtIndexPath:indexPath];
    [self showSelectionsActionBarAnimated:YES];
    [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
    [self.guiCollectionView reloadData];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_stopSelectingEmus
{
    [self.dataSource disableSelections];
    [self.dataSource clearSelections];
    [self hideSelectionsActionBarAnimated:YES];
    [self.guiCollectionView reloadData];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_clearAllEmuSelections
{
    [self.dataSource clearSelections];
    [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
    [self.guiCollectionView reloadData];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_toggleTopPackSelection
{
    [self scrollToSection:self.currentTopSection animated:YES];
    [self.dataSource toggleSelectionForEmusAtSection:self.currentTopSection];
    [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
    [self.guiCollectionView reloadData];
}

#pragma mark - Gesture recognizer handlers
-(void)onLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    CGPoint position = [recognizer locationInView:recognizer.view];
    NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:position];
    if (indexPath) {
        if (self.currentState == EMEmusFeedStateBrowsing) {
            // Long press on a cell while browsing.
            // Change to selection state and choose the emu pressed.
            [self updateState:EMEmusFeedStateSelecting info:@{@"indexPath":indexPath}];
            [self.navBarVC updateUIByCurrentState];
        }
    }
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
