//
//  StoreVC.m
//  emu
//
//  Created by Aviv Wolf on 16/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMStoreVC.h"
#import "EMNavBarVC.h"
#import "EMStoreDataSource.h"
#import "EMNotificationCenter.h"
#import "EMBackend+AppStore.h"
#import <UIView+Toast.h>

@interface EMStoreVC () <
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiContactingStoreActivity;

@property (nonatomic) EMNavBarVC *navBarVC;
@property (nonatomic) id<UICollectionViewDataSource> dataSource;
@property (nonatomic) CGSize bigCellSize;
@property (nonatomic) CGSize smallCellSize;

@end

@implementation EMStoreVC

#pragma mark - Initializations
+(EMStoreVC *)storeVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Store" bundle:nil];
    EMStoreVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"store vc"];
    return vc;
}

-(void)initGUIOnLoad
{
    self.dataSource = [EMStoreDataSource new];
    self.guiCollectionView.dataSource = self.dataSource;
    self.guiCollectionView.delegate = self;
    
    // Cell sizes
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat w = screenRect.size.width;
    
    self.bigCellSize = CGSizeMake(w, 160.0f);
    self.smallCellSize = CGSizeMake(w, 100.0f);
    
    // Store connection activity
    [self showActivityAnimated:NO];
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUIOnLoad];
    [self initNavigationBar];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showActivityAnimated:NO];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [EMBackend.sh storeRefreshProductsInfo];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On products info update
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:emkDataProductsInfoUpdated
                   object:nil];

    // On handled transactions
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:emkDataProductsHandledTransactions
                   object:nil];

    // On products restored
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:emkDataProductsRestoredPurchases
                   object:nil];

    // On products restored
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:emkDataProductsError
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataProductsInfoUpdated];
}

#pragma mark - Observers handlers
-(void)onProductsInfoUpdated:(NSNotification *)notification
{
    [self showStoreItemsAnimated:YES];
    EMStoreDataSource *dataSource = self.dataSource;
    [dataSource reloadData];
    [self.guiCollectionView reloadData];
    
    // If error encountered, show a toast with the localized description of the error.
    NSError *error = notification.userInfo[@"error"];
    if (error && [error localizedDescription]) {
        [self.view makeToast:[error localizedDescription] duration:1.3 position:CSToastPositionCenter];
    }
}

#pragma mark - Activity
-(void)showActivityAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showActivityAnimated:NO];
        }];
    }

    self.guiCollectionView.alpha = 0;
    self.guiContactingStoreActivity.alpha = 1;
    [self.guiContactingStoreActivity startAnimating];
}

-(void)showStoreItemsAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showStoreItemsAnimated:NO];
        }];
    }
    
    self.guiCollectionView.alpha = 1;
    self.guiContactingStoreActivity.alpha = 0;
    [self.guiContactingStoreActivity stopAnimating];
}

#pragma mark - Navigation bar
-(void)initNavigationBar
{
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeStore]];
}

#pragma mark - UICollectionViewDelegate

#pragma mark - UICollectionViewDelegateFlowLayout
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.item;
    if (index == 0) {
        return self.bigCellSize;
    } else {
        return self.smallCellSize;
    }
}

#pragma mark - Actions
-(void)buyProductWithPID:(NSString *)pid
{
    [self showActivityAnimated:YES];
    [EMBackend.sh buyProductWithIdentifier:pid];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBuyButton:(UIButton *)sender
{
    NSInteger index = sender.tag;
    EMStoreDataSource *dataSource = self.dataSource;
    NSString *pid = [dataSource productIdentifierAtIndex:index];
    if (pid) {
        [self buyProductWithPID:pid];
    }
}


@end
