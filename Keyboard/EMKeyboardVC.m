//
//  EMKeyboardVC.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMKeyboardVC.h"
#import "EMDB.h"
#import "EmuCell.h"
#import "EMShareCopy.h"
#import "HMReporter.h"

@interface EMKeyboardVC()<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessError;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessInstructions;

@property (nonatomic) Package *selectedPackage;
@property (nonatomic) BOOL initializedData;
@property (nonatomic) EMShareCopy *sharer;

@property (nonatomic) BOOL isFullAccessGranted;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;


@end

@implementation EMKeyboardVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.initializedData = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkForFullAccess];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isFullAccessGranted) {
        [self initData];
        [self initAnalytics];
    }
    [self updateGUI];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

#pragma mark - Analytics
-(void)initAnalytics
{
    [HMReporter.sh initializeAnalyticsWithLaunchOptions:nil];
    [HMReporter.sh analyticsEvent:AK_E_KB_DID_APPEAR info:nil];
    [HMReporter.sh analyticsForceSend];
}

#pragma mark - Initializations
-(void)initGUI
{
}

-(void)updateGUI
{
    // Full access error messages and instructions
    self.guiFullAccessError.hidden = self.isFullAccessGranted;
    self.guiFullAccessInstructions.hidden = self.isFullAccessGranted;
    [self.guiCollectionView reloadData];
}

#pragma mark - Data
-(void)initData
{
    if (!self.initializedData) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        self.selectedPackage = [appCFG packageForOnboarding];
    }
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
}

#pragma mark - KB helpers
-(void)checkForFullAccess
{
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if (pasteBoard == nil) {
        self.isFullAccessGranted = NO;
        return;
    }
    self.isFullAccessGranted = YES;
}

#pragma mark - Fetched results controller
-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@", @NO];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Root"];
    _fetchedResultsController = frc;
    
    NSError *error;
    [_fetchedResultsController performFetch:&error];
    
    return frc;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
    if (!self.isFullAccessGranted)
        return;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    if (!self.isFullAccessGranted) return 0;
    
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    self.guiDebugLabel.text = [SF: @"E:%@", @(count)];
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu cell";
    EmuCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                      forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = 120;
    CGFloat height = self.guiCollectionView.bounds.size.height;
    return CGSizeMake(width, height);
}



#pragma mark - Cell
-(void)configureCell:(EmuCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    if (emu.wasRendered.boolValue) {
        [cell.guiActivity stopAnimating];
        cell.animatedGifURL = [emu animatedGifURL];
    } else {
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        //        [EMRenderManager.sh enqueueEmu:emu info:@{
        //                                                  @"indexPath":indexPath,
        //                                                  @"emuticonOID":emu.oid
        //                                                  }];
    }
    
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self copyEmu:emu];
}

#pragma mark - Analytics
-(HMParams *)paramsForEmuticon:(Emuticon *)emuticon
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emuticon.emuDef.name];
    [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emuticon.emuDef.oid];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emuticon.emuDef.package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emuticon.emuDef.package.oid];
    return params;
}

#pragma mark - Sharing
-(void)copyEmu:(Emuticon *)emu
{
    if (emu == nil || self.sharer != nil) return;
    
    
    // Info about the share
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:@"copy"];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"keyboard"];
    [HMReporter.sh analyticsEvent:AK_E_KB_USER_PRESSED_ITEM info:params.dictionary];
    
    self.sharer = [EMShareCopy new];
    self.sharer.objectToShare = emu;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    self.sharer.info = params.dictionary;
    [self.sharer share];
}

#pragma mark - EMShareDelegate
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_SUCCESS info:info];
    [HMReporter.sh analyticsForceSend];
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_FAILED info:info];
    [HMReporter.sh analyticsForceSend];
}


-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_CANCELED info:info];
    [HMReporter.sh analyticsForceSend];
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNextKBButton:(id)sender
{
    [self.delegate keyboardShouldAdadvanceToNextInputMode];
    [HMReporter.sh analyticsEvent:AK_E_KB_USER_PRESSED_NEXT_INPUT_BUTTON];
}

- (IBAction)onPressedBackButton:(id)sender
{
    [self.delegate keyboardShouldDeleteBackward];
    [HMReporter.sh analyticsEvent:AK_E_KB_USER_PRESSED_BACK_BUTTON];
}

@end
