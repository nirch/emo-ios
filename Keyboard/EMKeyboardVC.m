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
    }
    [self updateGUI];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
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

#pragma mark - Sharing
-(void)copyEmu:(Emuticon *)emu
{
    if (emu == nil || self.sharer != nil) return;
    
    self.sharer = [EMShareCopy new];
    self.sharer.objectToShare = emu;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    [self.sharer share];
}

#pragma mark - EMShareDelegate
-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNectKBButton:(id)sender
{
    [self.delegate keyboardShouldAdadvanceToNextInputMode];
}

@end
