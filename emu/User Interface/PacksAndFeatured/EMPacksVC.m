//
//  EMPacksVC.h
//  emu
//  -----------------------------------------------------------------------
//  Responsibilities:
//      - Showing list of packs.
//      - When user selectes a pack,
//        will broadcast a notification with info about the selected pack.
//      - Sometimes notifies "requires data fetch"
//        (lets someone else decide if a fetch actually required).
//  -----------------------------------------------------------------------
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPacksVC.h"
#import "EMPackCell.h"
#import "EMNavBarVC.h"
#import "EMPacksDataSource.h"
#import "EMTopVCProtocol.h"
#import "EMNotificationCenter.h"
#import "EMUINotifications.h"
#import "EMGradientView.h"
#import "EMDB.h"

#define TAG @"EMPacksVC"

#import <PINRemoteImageManager.h>
#import <PINCache.h>

#define PACKS_CELLS_ASPECT_RATIO 2.8f
#define PACKS_PADDING_H 12.0f

@interface EMPacksVC () <
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    EMTopVCProtocol
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiFeaturedPacksContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (strong, nonatomic) IBOutlet EMGradientView *guiGradientBG;

// UI initialization
@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;
@property (nonatomic) NSString *highlightedPackOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;

// The data source.
@property (nonatomic) EMPacksDataSource *dataSource;

// YES/NO flag indicating if the featured packs are shown on this view controller.
@property (nonatomic, readwrite) BOOL featuredPacksShown;

// Layout info.
@property (nonatomic) CGFloat packCellHeight;
@property (nonatomic) CGFloat packCellWidth;
@property (nonatomic) CGFloat packsTopPosition;

@end

@implementation EMPacksVC

+(EMPacksVC *)packsVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PacksAndFeatured" bundle:nil];
    EMPacksVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"featured vc"];
    vc.featuredPacksShown = NO;
    return vc;
}

+(EMPacksVC *)packsVCWithFeaturedPacks
{
    EMPacksVC *vc = [EMPacksVC packsVC];
    vc.featuredPacksShown = YES;
    return vc;
}

#pragma mark - VC lifecycle
/**
 *  On view did load:
 *      - initialize the data source for this packs VC collection view.
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

    self.guiGradientBG.hideGradientBackground = self.hideGradientBackground;

    // Init observers
    [self initObservers];

    // Refresh data if required
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages object:self userInfo:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HMLOG(TAG, EM_DBG, @"View did appear");
    [self refreshGUIWithLocalData];
    [self initGUIOnAppearance];
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    return self.featuredPacksShown;
}

#pragma mark - Initializations
/**
 *  Initialized the data source for the collection view of packs.
 */
-(void)initDataSource
{
    // Set the data source.
    self.dataSource = [EMPacksDataSource new];
    self.guiCollectionView.dataSource = self.dataSource;
    [self.dataSource reset];
}

/**
 *  GUI initializations on first loading the UI.
 */
-(void)initGUIOnLoad
{
    // Initialize the UI
    self.guiCollectionView.backgroundColor = [UIColor clearColor];
    self.guiCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Will fade in the collection view and the featured packs view later.
    self.guiCollectionView.alpha = 0;
    self.guiFeaturedPacksContainer.alpha = 0;
}

-(void)initNavigationBar
{
    EMNavBarVC *navBarVC;
    if (self.featuredPacksShown) {
        navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeatured]];
        self.navBarVC = navBarVC;
    }
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
        CGRect containerRect = self.view.bounds;
        CGSize size = containerRect.size;
        
        // Cells settings
        self.packCellWidth = (CGFloat)(int)(size.width/2 - PACKS_PADDING_H) ;
        self.packCellHeight = (CGFloat)(int)self.packCellWidth / PACKS_CELLS_ASPECT_RATIO;
        
        // Collection view settings
        CGRect f = self.guiFeaturedPacksContainer.frame;
        if (self.featuredPacksShown) {
            self.packsTopPosition = f.origin.y + f.size.height + 6;
            self.guiFeaturedPacksContainer.hidden = NO;
        } else {
            self.packsTopPosition = f.origin.y + 6;
            self.guiFeaturedPacksContainer.hidden = YES;
        }

        if (self.dataSource.packsCount > 10 && self.guiCollectionView.alpha == 0) {
            [self revealPacks];
        } else {
            [self.guiActivity startAnimating];
        }

        self.alreadyInitializedGUIOnAppearance = YES;
        
        if (self.highlightedPackOnAppearance) {
            [self _highlightPackWithOID:self.highlightedPackOnAppearance];
            self.highlightedPackOnAppearance = nil;
        }
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
    
    [nc addUniqueObserver:self
                 selector:@selector(onDebug:)
                     name:emkDataDebug
                   object:nil];

}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataUpdatedPackages];
    [nc removeObserver:emkDataDebug];
}

#pragma mark - Observers handlers
-(void)onUpdatedData:(NSNotification *)notification
{
    [self refreshGUIWithLocalData];
    if (self.guiCollectionView.alpha == 0) {
        [self revealPacks];
    }
}

-(void)onDebug:(NSNotification *)notification
{
}

#pragma mark - Data
-(void)refreshGUIWithLocalData
{
    // Reload the data in the collection view.
    [self.dataSource reset];
    [self.guiCollectionView reloadData];
}

#pragma mark - EMTopVCProtocol
-(void)vcWasSelectedWithInfo:(NSDictionary *)info
{
    HMLOG(TAG, EM_DBG, @"Top vc selected: EMPacksVC");
}

#pragma mark - Show / Hide UI elements
-(void)revealPacks
{
    [self.guiActivity stopAnimating];
    self.guiFeaturedPacksContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [UIView animateWithDuration:0.8 animations:^{
        self.guiFeaturedPacksContainer.alpha = 1;
        self.guiFeaturedPacksContainer.transform = CGAffineTransformIdentity;
    }];

    [UIView animateWithDuration:0.1 animations:^{
        self.guiCollectionView.alpha = 1;
    }];
}

#pragma mark - Highlighting
-(void)removeHighlights
{
    
}

-(void)highlightPackWithOID:(NSString *)packOID
{
    if (self.alreadyInitializedGUIOnAppearance) {
        if (packOID != nil) [self _highlightPackWithOID:packOID];
    } else {
        self.highlightedPackOnAppearance = packOID;
    }
}

-(void)_highlightPackWithOID:(NSString *)packOID
{
    NSIndexPath *indexPath = [self.dataSource indexPathByPackOID:packOID];
    [self.guiCollectionView scrollToItemAtIndexPath:indexPath
                                   atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                           animated:NO];
    

    __weak EMPacksVC *weakSelf = self;
    dispatch_after(DTIME(0.5), dispatch_get_main_queue(), ^{
        UICollectionViewCell *cell = [weakSelf.guiCollectionView cellForItemAtIndexPath:indexPath];
        
        // Repeating animation of the highlighted cell.
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.7
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse
                         animations:^{
                             cell.alpha = 0.85;
                             cell.transform = CGAffineTransformMakeScale(1.08, 1.08);
                         } completion:nil];
    });
}

#pragma mark - Collection view layout
/**
 *  Determine the required layout for a cell in a given index path.
 *
 *  @param collectionView       The related collection view.
 *  @param collectionViewLayout The layout.
 *  @param indexPath            Index path of the cel.
 *
 *  @return CGSize required for the cell.
 */
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Packs can be shown two or one per row.
    BOOL shouldBeWideButton = indexPath.item < self.dataSource.lastWidePack;
    
    if (shouldBeWideButton) {
        // A wide button for this pack.
        return CGSizeMake(self.packCellWidth * 2, self.packCellHeight);
    } else {
        // A narrow button for this pack (two per row).
        return CGSizeMake(self.packCellWidth, self.packCellHeight);
    }
}

/**
 *  Inset for a section. Just adding some padding to the collection view.
 *
 *  @param collectionView       The related collection view.
 *  @param collectionViewLayout The collection view layout.
 *  @param section              The section number.
 *
 *  @return The required insets (padding) for the provided section number.
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(self.packsTopPosition, PACKS_PADDING_H, 50, PACKS_PADDING_H);
    return edgeInsets;
}


#pragma mark - Scrolling
/**
 *  Just a silly bounce/stretch effect on the featured packs view.
 *
 *  @param scrollView The scroll view.
 */
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat scale = 1.0f;
    if (offset >= 0) {
        if (!CGAffineTransformIsIdentity(self.guiFeaturedPacksContainer.transform))
            self.guiFeaturedPacksContainer.transform = CGAffineTransformIdentity;
    } else {
        offset = offset / 5.0f;
        scale += fabs(offset) / 100.0f;
    }
    
    CGAffineTransform t = CGAffineTransformMakeTranslation(0, -offset);
    if (scale > 1.0f) t = CGAffineTransformScale(t, scale, scale);
    self.guiFeaturedPacksContainer.transform = t;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedPackButton:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    NSString *packOID = [self.dataSource packOIDByIndexPath:indexPath];
    if (packOID == nil) return;
    
    // Notify that a pack was selected.
    NSDictionary *info = @{emkPackageOID:packOID};
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserSelectedPack
                                                        object:self
                                                      userInfo:info];
}


@end
