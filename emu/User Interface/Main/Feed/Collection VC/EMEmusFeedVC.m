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
#import "EMPackHeaderView.h"
#import "EMUISound.h"
#import "EMFeedSelectionsActionBarVC.h"
#import "EMHolySheet.h"
#import "EMMajorRetakeOptionsSheet.h"
#import "EMInterfaceDelegate.h"
#import "EMRecorderDelegate.h"
#import "EMFootagesVC.h"
#import "EMAlertsPermissionVC.h"
#import "AppManagement.h"
#import "EMProductPopover.h"
#import "EMBackend+AppStore.h"
#import "emu-Swift.h"
#import <SIAlertView.h>
#import "EmuStyle.h"

#define TAG @"EMEmusFeedVC"

@interface EMEmusFeedVC() <
    UICollectionViewDelegateFlowLayout,
    EMNavBarDelegate,
    UIGestureRecognizerDelegate,
    EMInterfaceDelegate,
    EMRecorderDelegate
>

// The emus feed collection view.
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

// UI initialization
@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (weak, nonatomic) EMCustomPopoverVC *popoverController;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;
typedef NS_ENUM(NSInteger, EMEmusFeedTitleState) {
    EMEmusFeedTitleStateLogo                     = 0,
    EMEmusFeedTitleStatePacks                    = 1,
    EMEmusFeedTitleStateHint                     = 2
};
@property (nonatomic) EMEmusFeedTitleState titleState;


// Selection actions bar
@property (weak, nonatomic) IBOutlet UIView *guiSelectionActionsBar;
@property (weak, nonatomic) EMFeedSelectionsActionBarVC *selectionsActionBarVC;

// The data source.
@property (nonatomic) EMEmusFeedDataSource *dataSource;

// Current top section
@property (nonatomic, readonly) NSInteger currentTopSection;

// Footages VC
@property (nonatomic, weak) EMFootagesVC *footagesVC;

// Ask user about alerts permission
@property (nonatomic, weak) EMAlertsPermissionVC *alertsPermissionVC;

@property (nonatomic) BOOL inScroll;

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
    self.guiCollectionView.alpha = 0;
    
    // Init observers
    [self initObservers];
    
    // Refresh data if required
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages object:self userInfo:nil];

    // Data
    [self refreshGUIWithLocalData];
}


/**
 *  More initialization and state checks on appearance.
 */
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HMLOG(TAG, EM_DBG, @"View did appear");
    [self initGUIOnAppearance];
    [self.navBarVC bounce];
    [self restoreState];
    dispatch_after(DTIME(1), dispatch_get_main_queue(), ^{
        [self handleVisibleCells];
    });
    
    // Show the tabs
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@YES}];
    [UIView animateWithDuration:0.2 animations:^{
        self.navBarVC.view.alpha = 1;
    }];
    
    // Reveal
    if (self.guiCollectionView.alpha == 0) {
        [UIView animateWithDuration:0.3 animations:^{
            self.guiCollectionView.alpha = 1;
        }];
    }
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
    [self storeState];
}

#pragma mark - Persisting state
-(void)storeState
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    // Store offset.
    CGFloat latestOffset = self.guiCollectionView.contentOffset.y;
    [ud setObject:@(latestOffset) forKey:@"feedOffset"];

    // Sync
    [ud synchronize];
}

-(void)restoreState
{
    if (self.requestsPackageOID) [self consumeNavigationRequests];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    // Restore offset.
    NSNumber *offsetNumber = [ud objectForKey:@"feedOffset"];
    if (offsetNumber == nil) return;
    CGPoint latestOffset = CGPointMake(0, offsetNumber.doubleValue);
    [self.guiCollectionView setContentOffset:latestOffset];
    [self.navBarVC childVCDidScrollToOffset:latestOffset];
}

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selections action bar segue"]) {
        
        self.selectionsActionBarVC = segue.destinationViewController;
        self.selectionsActionBarVC.delegate = self;
        
    }
}

#pragma mark - Initializations
/**
 *  Initialize the feed to the browsing / normal state.
 */
-(void)initState
{
    self.inScroll = NO;
    self.titleState = EMEmusFeedTitleStateLogo;
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
    self.guiCollectionView.alpha = 0;
    
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
        self.alreadyInitializedGUIOnAppearance = YES;
        [self.navBarVC updateTitle:[SF:@"%@ %@", LS(@"PACKS"), @"▼"]];
    }
    
    // ABTEST:Main feed deceleration speed.
    BOOL fasterDeceleration = [HMPanel.sh boolForKey:VK_MAIN_FEED_SCROLL_DECELERATION_SPEED fallbackValue:NO];
    if (fasterDeceleration) {
        self.guiCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    } else {
        self.guiCollectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // On packages data updated.
    [nc addUniqueObserver:self
                 selector:@selector(onUpdatedData:)
                     name:emkDataUpdatedPackages
                   object:nil];
    
    // On user selected a pack
    [nc addUniqueObserver:self
                 selector:@selector(onUserSelectedAPack:)
                     name:emkUIUserSelectedPack
                   object:nil];
    
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
    
    // Store transactions handled.
    [nc addUniqueObserver:self
                 selector:@selector(onHandledStoreTransactions:)
                     name:emkDataProductsHandledTransactions
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataUpdatedPackages];
    [nc removeObserver:emkUIUserSelectedPack];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:hmkDownloadResourceFinished];
    [nc removeObserver:emkDataProductsHandledTransactions];
}

#pragma mark - Observers handlers
-(void)onHandledStoreTransactions:(NSNotification *)notification
{
    [self.guiCollectionView reloadData];
}


-(void)onUpdatedData:(NSNotification *)notification
{
    [self refreshGUIWithLocalData];
}

-(void)onUserSelectedAPack:(NSNotification *)notification
{
    // User pressed a pack in the packs popover.
    // Dismiss the popover and scroll to the selected pack.
    NSString *packOID = notification.userInfo[emkPackageOID];
    __weak EMEmusFeedVC *weakSelf = self;
    
    if (self.popoverController) {
        [self.popoverController dismissViewControllerAnimated:YES completion:^{
            if (packOID == nil) return;
            NSIndexPath *indexPath = [weakSelf.dataSource indexPathForPackOID:packOID];
            if (indexPath == nil) return;
            [self scrollToSection:indexPath.section animated:NO];
        }];
    } else {
        NSIndexPath *indexPath = [weakSelf.dataSource indexPathForPackOID:packOID];
        if (indexPath == nil) return;
        [self scrollToSection:indexPath.section animated:NO];
    }
    
    Package *pack = [Package findWithID:packOID context:EMDB.sh.context];
    [self _handleChangeToPackage:pack];
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
        NSIndexPath *indexPath = info[emkIndexPath];
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
    [self reload];
    if (self.requestsPackageOID) [self consumeNavigationRequests];
}

-(void)consumeNavigationRequests
{
    if (self.requestsPackageOID) {
        NSString *packageOID = self.requestsPackageOID;
        NSString *emuOID = self.requestsEmuOID;
        
        Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
        [self _handleChangeToPackage:package];
        NSIndexPath *indexPath = [self.dataSource indexPathForPackOID:self.requestsPackageOID];
        if (indexPath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollToSection:indexPath.section animated:NO];
                
                if (self.navigationController.presentingViewController.presentedViewController != self) {
                    // Another vc is already pushed on the stack
                    [self.navigationController popToViewController:self animated:NO];
                }
                
                Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
                if (emu) [self navigateToEmuOID:emu.oid animated:NO];
            });
        }
        self.requestsEmuOID = nil;
        self.requestsPackageOID = nil;
        return;
    }
}

#pragma mark - EMTopVCProtocol
-(void)vcWasSelectedWithInfo:(NSDictionary *)info
{
    HMLOG(TAG, EM_DBG, @"Top vc selected: EMEmusFeedVC");
}

#pragma mark - Navigating to emu screen
-(void)navigateToEmuOID:(NSString *)emuOID animated:(BOOL)animated
{
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    if (emu == nil) return;

    EmuScreenVC *emuScreenVC = [EmuScreenVC emuScreenVC:emu.emuDef.oid
                                             themeColor:self.navBarThemeColor];
    [self.navigationController pushViewController:emuScreenVC animated:animated];
    self.guiCollectionView.userInteractionEnabled = YES;
}

#pragma mark - Collection view Layout
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat pad = 0.0;
    CGFloat aspectRatio = [self.dataSource aspectRatioForItemAtIndexPath:indexPath];
    CGFloat width = (self.view.bounds.size.width - pad) / 2.0;
    CGFloat height = width;
    if (aspectRatio != 1.0) {
        width = (self.view.bounds.size.width - pad);
        height = width / aspectRatio;
    }
    return CGSizeMake(width, height);
}

-(NSInteger)currentTopSection
{
    NSInteger topSection = NSIntegerMax;
    NSArray *visibleCells = [self.guiCollectionView visibleCells];
    if (visibleCells == 0) {
        // Not likely, probably will never happen, but just in case (on test apps for example)
        UICollectionView *cv = self.guiCollectionView;
        CGPoint p = CGPointMake(cv.center.x, 52+cv.contentOffset.y);
        NSIndexPath *indexPath = [cv indexPathForItemAtPoint:p];
        topSection = indexPath.section;
    } else {
        for (EMEmuCell *cell in visibleCells) {
            topSection = MIN(topSection, cell.sectionIndex);
        }
    }
    topSection = topSection < NSIntegerMax?topSection:0;
    CGFloat offsetY = self.guiCollectionView.contentOffset.y;
    if (offsetY > 0) topSection ++;
    return topSection;
}


#pragma mark - Collection view
-(void)reload
{
    [self.guiCollectionView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleVisibleCells];
    });
}

#pragma mark - Dedicated footage
-(void)askUserIfWantsADedicatedFootageForEmu:(Emuticon *)emu
{
    if (![emu.emuDef requiresDedicatedCapture]) return;
    
    SIAlertView *alert = [[SIAlertView alloc] initWithTitle:[emu.emuDef emuStoryTimeTitle] andMessage:LS(@"DEDICATED_FOOTAGE_REQUIRED_MESSAGE")];
    alert.buttonColor = [EmuStyle colorButtonBGPositive];
    alert.cancelButtonColor = [EmuStyle colorButtonBGNegative];
    [alert addButtonWithTitle:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU") type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
        // Recorder should be opened for a retake.
        HMParams *requestInfo = [HMParams new];
        [requestInfo addKey:emkRetakeEmuticonsOID value:@[emu.oid]];
        [requestInfo addKey:emkDuration value:emu.emuDef.captureDuration];
        
        // Notify main navigation controller that the recorder should be opened.
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserRequestToOpenRecorder
                                                            object:self
                                                          userInfo:requestInfo.dictionary];
    }];
    [alert addButtonWithTitle:LS(@"CANCEL") type:SIAlertViewButtonTypeCancel handler:nil];
    [alert show];
}

#pragma mark - Collection View Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    if (indexPath == nil) return;
    
    NSString *oid = [self.dataSource emuOIDAtIndexPath:indexPath];
    if (self.dataSource.failedOIDS[oid]) {
        [self.dataSource.failedOIDS removeAllObjects];
        [self refreshGUIWithLocalData];
        return;
    }
    
    if (self.currentState == EMEmusFeedStateBrowsing) {
        // -------------------------------------------------------
        // Tapped emu when browsing.
        //
        NSString *emuOID = [self.dataSource emuOIDAtIndexPath:indexPath];
        if (emuOID == nil) return;
        
        // Emus that require a dedicated footage and still don't have such
        // footage taken yet, will popup a question to the user about taking
        // the dedicated footage.
        Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
        if ([emu.mostPrefferedUserFootage isKindOfClass:[PlaceHolderFootage class]]) {
            [self askUserIfWantsADedicatedFootageForEmu:emu];
            return;
        }
        
        // When browsing, selection of an emu will navigate to the emu screen.
        // Also post a notification that the tabs bar (if shown) should be hidden.
        
        self.guiCollectionView.userInteractionEnabled = NO;
        dispatch_after(DTIME(0.2), dispatch_get_main_queue(), ^{
            [self navigateToEmuOID:emuOID animated:YES];
        });

    } else if (self.currentState == EMEmusFeedStateSelecting) {
        // -------------------------------------------------------
        // Tapped emu when in selections mode.
        //
        
        // When on selection state, will select/unselect the emu when tapping an emu.
        [self.dataSource toggleSelectionForEmuAtIndexPath:indexPath];
        [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
        [self.guiCollectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}


-(void)updateTitleStateForOffset:(CGPoint)offset
{
    CGFloat y = offset.y;
    HMLOG(TAG, EM_DBG, @"%@", @(y));
    if (self.titleState == EMEmusFeedTitleStateLogo || self.titleState == EMEmusFeedTitleStatePacks) {
        if (y>800) {
            self.titleState = EMEmusFeedTitleStateHint;
            [self.navBarVC updateTitle:@"▼"];
            [self.navBarVC updateTitleAlpha:0.5];
        }
    } else if (self.titleState == EMEmusFeedTitleStateHint) {
        if (y<800) {
            self.titleState = EMEmusFeedTitleStatePacks;
            [self.navBarVC updateTitleAlpha:1.0];
        }
    }
}

#pragma mark - Scrolling
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Update the nav bar where did we scroll to.
    CGPoint offset = scrollView.contentOffset;
    offset.y += scrollView.contentInset.top;
    [self.navBarVC childVCDidScrollToOffset:offset];
    
    if (!self.inScroll && scrollView.isDragging) {
        self.inScroll = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldHideTabsBar
                                                            object:self
                                                          userInfo:@{emkUIAnimated:@(YES)}];
        [UIView animateWithDuration:0.2 animations:^{
            self.navBarVC.view.alpha = 0;
        }];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self handleVisibleCells];
    
    self.inScroll = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@(YES)}];
    [UIView animateWithDuration:0.2 animations:^{
        self.navBarVC.view.alpha = 1;
    }];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self handleVisibleCells];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                    withVelocity:(CGPoint)velocity
             targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (fabs(velocity.y) > 1.5f) {
        // On high enough velocity, change the target to the top
        // of a pack, so will decelerate to a position putting
        // the header of that pack at the top of the screen.
        // Result: when user flicks the scroll view, the end result
        // is a pack positioned nicely on the screen.
        CGPoint target = CGPointMake(20, targetContentOffset->y);
        NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:target];
        if (indexPath == nil) return;
        NSInteger section = indexPath.section;
        if (velocity.y>0) section++;
        *targetContentOffset = [self offsetForHeaderForSection:section];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        // Will not decelerate after dragging, so scrolling just ended.
        [self handleVisibleCells];

        self.inScroll = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                            object:self
                                                          userInfo:@{emkUIAnimated:@(YES)}];
        [UIView animateWithDuration:0.2 animations:^{
            self.navBarVC.view.alpha = 1;
        }];
    }
}

-(void)scrollToSection:(NSInteger)sectionIndex animated:(BOOL)animated
{
    CGPoint newOffset = [self offsetForHeaderForSection:sectionIndex];
    [self.guiCollectionView setContentOffset:newOffset animated:animated];
    CGFloat delay = animated?0.7f:0.0f;
    dispatch_after(DTIME(delay), dispatch_get_main_queue(), ^{
        [self handleVisibleCells];
        self.inScroll = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                            object:self
                                                          userInfo:@{emkUIAnimated:@(YES)}];
        [UIView animateWithDuration:0.2 animations:^{
            self.navBarVC.view.alpha = 1;
        }];
    });
}

-(CGRect)frameForHeaderForSection:(NSInteger)section
{
    // Check if not empty data
    if (self.dataSource.packsCount < 1) {
        return CGRectMake(0,0,1,1);
    }
    
    // Make sure section is in bound
    if (section >= self.dataSource.packsCount) {
        section = self.dataSource.packsCount-1;
    }
    if (section < 0) section = 0;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    UICollectionViewLayoutAttributes *attributes = [self.guiCollectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGRect frameForFirstCell = attributes.frame;
    CGFloat headerHeight = 19;
    return CGRectOffset(frameForFirstCell, 0, -headerHeight);
}

-(CGPoint)offsetForHeaderForSection:(NSInteger)section
{
    CGRect rectOfHeader = [self frameForHeaderForSection:section];
    CGPoint newOffset = CGPointMake(0, rectOfHeader.origin.y - self.guiCollectionView.contentInset.top - 7);
    return newOffset;
}

#pragma mark - Handle visible cell
-(void)handleVisibleCells
{
    NSArray *visibleIndexPaths = self.guiCollectionView.indexPathsForVisibleItems;
    [self.dataSource preferEmusAtIndexPaths:visibleIndexPaths];
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

-(void)navBarOnLogoButtonPressed:(UIButton *)sender
{
    if (AppManagement.sh.isTestApp) {
        [self showPacksListAsPopOver:sender];
        return;
    }
    
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
        
        Package *pack = [self.dataSource packForSection:self.currentTopSection];
        if (pack == nil) return;

        // Sheet happens!
        EMMajorRetakeOptionsSheet *sheet = [[EMMajorRetakeOptionsSheet alloc] initWithPackOID:pack.oid packLabel:pack.label packName:pack.name];
        sheet.interfaceDelegate = self;
        [sheet showModalOnTopAnimated:YES];
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_CANCEL_SELECTION]) {
        
        // Do nothing and change back to the browsing state.
        [self updateState:EMEmusFeedStateBrowsing info:nil];
        [self.navBarVC updateUIByCurrentState];
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_SELECT_PACK]) {
        
        [self _toggleTopPackSelection];
        
    }
}

-(UIColor *)navBarThemeColor
{
    return self.navBarVC.themeColor;
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
    [UIView animateWithDuration:0.2 animations:^{
        self.navBarVC.view.alpha = 1;
    }];
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
    [self reload];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_stopSelectingEmus
{
    [self.dataSource disableSelections];
    [self.dataSource clearSelections];
    [self hideSelectionsActionBarAnimated:YES];
    [self reload];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_clearAllEmuSelections
{
    [self.dataSource clearSelections];
    [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
    [self reload];
}

/**
 *  Important: call this method only from the VC state machine.
 */
-(void)_toggleTopPackSelection
{
    [self scrollToSection:self.currentTopSection animated:YES];
    [self.dataSource toggleSelectionForEmusAtSection:self.currentTopSection];
    [self.selectionsActionBarVC setSelectedCount:self.dataSource.selectionsCount];
    [self reload];
}


#pragma mark - Gesture recognizer handlers
-(void)onLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    CGPoint position = [recognizer locationInView:recognizer.view];
    NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:position];
    if (indexPath) {
        if (self.currentState == EMEmusFeedStateBrowsing) {
            // -------------------------------------------------------
            // Long press emu when browsing.
            //
            NSString *emuOID = [self.dataSource emuOIDAtIndexPath:indexPath];
            if (emuOID == nil) return;
            
            // Emus that require a dedicated footage will popup a question to the user
            // about taking the dedicated footage.
            Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
            if (emu.emuDef.requiresDedicatedCapture) {
                [self askUserIfWantsADedicatedFootageForEmu:emu];
                return;
            }
            
            // Long press on a regular cell while browsing.
            // Change to selection state and choose the emu pressed.
            [self updateState:EMEmusFeedStateSelecting info:@{emkIndexPath:indexPath}];
            [self.navBarVC updateUIByCurrentState];
        }
    }
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:emkSelectionsActionRetakeSelected]) {
        // -------------------------------------------
        // Open recorder for retaking selected emus.
        //

        // Must be in selections state
        if (self.currentState != EMEmusFeedStateSelecting) return;
        
        // Must select at least one
        if (self.dataSource.selectionsCount < 1) {
            [self.selectionsActionBarVC communicateErrorToUser];
            return;
        }
        
        // Recorder should be opened for a retake.
        NSMutableDictionary *requestInfo = [NSMutableDictionary new];
        requestInfo[emkRetakeEmuticonsOID] = [self.dataSource selectionsOID];
        
        // Notify main navigation controller that the recorder should be opened.
        [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserRequestToOpenRecorder
                                                            object:self
                                                          userInfo:requestInfo];

        // Change feed back to browsing state
        [self updateState:EMEmusFeedStateBrowsing info:nil];
        [self.navBarVC updateUIByCurrentState];
    
    } else if ([actionName isEqualToString:emkSelectionsActionReplaceSelected]) {
        // -------------------------------------------
        // Open takes screen for choosing a different take for selected emus.
        //
        
        // Must be in selections state
        if (self.currentState != EMEmusFeedStateSelecting) return;
        
        // Must select at least one
        if (self.dataSource.selectionsCount < 1) {
            [self.selectionsActionBarVC communicateErrorToUser];
            return;
        }

        // Present the footages screen
        EMFootagesVC *footagesVC = [EMFootagesVC footagesVCForFlow:EMFootagesFlowTypeChooseFootage];
        footagesVC.delegate = self;
        footagesVC.selectedEmusOID = self.dataSource.selectionsOID;
        self.footagesVC = footagesVC;
        [self presentViewController:footagesVC animated:YES completion:^{
        }];
        
        // Change feed back to browsing state
        [self updateState:EMEmusFeedStateBrowsing info:nil];
        [self.navBarVC updateUIByCurrentState];

    } else if ([actionName isEqualToString:emkUIFootageSelectionCancel]) {
        // -------------------------------------------
        // Footage selection canceled. Just dismiss.
        //
        [self dismissViewControllerAnimated:YES completion:^{
        }];
        
    } else if ([actionName isEqualToString:emkUIFootageSelectionApply]) {

        NSString *footageOID = info[emkFootageOID];
        NSArray *selectedEmusOID = info[emkEmuticonOID];
        if (footageOID != nil || selectedEmusOID != nil) {
            for (NSString *emuOID in selectedEmusOID) {
                Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
                [emu cleanUp:YES andRemoveResources:NO];
                emu.prefferedFootageOID = footageOID;
            }
        }
        [EMDB.sh save];

        // -------------------------------------------
        // New footage applied to a list of selected emus.
        //
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if ([actionName isEqualToString:emkUIPurchaseHDContent]) {
        
        NSString *packageOID = info[emkPackageOID];
        
        // User pressed the purchase button
        [HMPanel.sh analyticsEvent:AK_E_IAP_PRODUCT_USER_PRESSED_PURCHASE_BUTTON info:info];
        
        if (packageOID) {
            [self purchaseHDContentForPackageOID:packageOID withInfo:info];
        }

    } else if ([actionName isEqualToString:EMK_NAV_ACTION_NEW_TAKE]) {
        [self openRecorderForNewTake];
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_MY_TAKES]) {
        [self openFootagesScreen];
    } else if ([actionName isEqualToString:emkUIFootagesManageDone]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

}

#pragma mark - New and existing takes
-(void)openFootagesScreen
{
    // Present the footages screen
    EMFootagesVC *footagesVC = [EMFootagesVC footagesVCForFlow:EMFootagesFlowTypeMangementScreen];
    footagesVC.delegate = self;
    footagesVC.themeColor = self.navBarVC.themeColor;
    self.footagesVC = footagesVC;
    [self presentViewController:footagesVC animated:YES completion:nil];
}

-(void)openRecorderForNewTake
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST fallbackValue:nil];
    EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];

    NSDictionary *configInfo =@{
                                emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                emkEmuticonDefName:emuticonDefForOnboarding.name
                                };

    EMRecorderVC2 *recorderVC = [EMRecorderVC2 recorderVCWithConfigInfo:configInfo];
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:nil];
}

#pragma mark - Handle change to package
/**
 *  Some logic that happens when user navigate to a specific package
 *  by choosing it with a button.
 *
 *  (this code will not run if the user just scrolls to a pack)
 *
 *  @param package The package to handle
 */
-(void)_handleChangeToPackage:(Package *)package
{
    if (package == nil) return;
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSInteger numberOfViewedPackagesBeforeAlertsQuestion = [AppCFG tweakedInteger:@"number_of_viewed_packages_before_alerts_question" defaultValue:0];
    NSInteger numberOfViewedPackages = [Package countNumberOfViewedPackagesInContext:EMDB.sh.context];
    if (!appCFG.userAskedInMainScreenAboutAlerts.boolValue) {
        // Never asked.
        // Ask the user if interested in background fetches / auto updates.
        if (numberOfViewedPackages >= numberOfViewedPackagesBeforeAlertsQuestion)
            [self askUserAboutAlerts];
    }
    
    // If package never viewed before by the user, count the event.
    if (!package.viewedByUser.boolValue) {
        [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_PACKAGES_NAVIGATED];
        [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_NAVIGATE_TO_ANOTHER_PACKAGE value:@YES];
    }
    
    // Mark package as viewed.
    package.viewedByUser = @YES;
    [EMDB.sh save];

}

#pragma mark - Alerts question
-(void)showAlertsPermissionScreenAnimated:(BOOL)animated
{
    if (self.alertsPermissionVC == nil) {
        self.alertsPermissionVC = [EMAlertsPermissionVC alertsPermissionVCInParentVC:self];
    }
    [self.alertsPermissionVC showAnimated:animated];
}

-(void)askUserAboutAlerts
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.userAskedInMainScreenAboutAlerts = @YES;
    [EMDB.sh save];
    dispatch_after(DTIME(2), dispatch_get_main_queue(), ^{
        [self showAlertsPermissionScreenAnimated:YES];
    });
}

#pragma mark - Purchases
-(void)productPopoverForSectionIndex:(NSInteger)sectionIndex sender:(UIView *)sender
{
    // If
    // package not found OR
    // package is not related to an HD product for sale OR
    // package is a product for sale but it was already unlocked
    // then ignore this event. Move along, nothing to see here.
    Package *package = [self.dataSource packForSection:sectionIndex];
    if (package == nil ||
        package.hdProductID == nil ||
        package.hdUnlocked.boolValue) return;
    
    // User still didn't unlock the HD feature of this pack.
    // And the product is a validated one.
    EMProductPopover *vc = [[EMProductPopover alloc] init];
    vc.preferredContentSize = CGSizeMake(240, 240);
    vc.packageOID = package.oid;
    vc.originUI = @"feed";
    vc.delegate = self;
    
    // Show the popover with the in app purchases info.
    UIPopoverPresentationController *po = vc.popoverPresentationController;
    po.sourceView = sender;
    po.sourceRect = sender.bounds;
    po.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)purchaseHDContentForPackageOID:(NSString *)packageOID withInfo:(NSDictionary *)info
{
    if (packageOID == nil) return;
    Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
    if (package == nil || package.hdAvailable == nil || !package.hdAvailable.boolValue) return;
    if (package.hdProductID == nil) return;
    [EMBackend.sh buyProductWithIdentifier:package.hdProductID];
}

#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedPackSectionButton:(UIButton *)sender
{
    NSInteger sectionIndex = sender.tag;
    
    // Ensure section index is in bounds.
    if (sectionIndex>0 && sectionIndex < [self.dataSource packsCount]) {
        [self scrollToSection:sectionIndex animated:YES];
    }
}

- (IBAction)onPressedPackSectionPriceButton:(UIButton *)sender
{
    NSInteger sectionIndex = sender.tag;
    if (sectionIndex>=0 && sectionIndex < [self.dataSource packsCount]) {
        [self productPopoverForSectionIndex:sectionIndex sender:sender];
    }
}

- (IBAction)onPressedPackSectionHDButton:(UIButton *)sender
{
    NSInteger sectionIndex = sender.tag;
    if (sectionIndex>=0 && sectionIndex < [self.dataSource packsCount]) {
        [self productPopoverForSectionIndex:sectionIndex sender:sender];
    }
}

@end
