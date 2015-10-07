//
//  EMPacksDataSource.m
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmusFeedDataSource.h"
#import "EMDB.h"
#import "EMEmuCell.h"
#import "EMPackHeaderView.h"
#import "Emuticon+DownloadsHelpers.h"

@interface EMEmusFeedDataSource()

@property (nonatomic, readwrite) NSInteger packsCount;

// The fetched results controller.
@property (nonatomic) NSFetchedResultsController *frc;

// Selections
@property (nonatomic) NSMutableDictionary *selectedIndexPaths;

@end

@implementation EMEmusFeedDataSource

@synthesize selectionsAllowed = _selectionsAllowed;

-(id)init
{
    self = [super init];
    if (self) {
        self.selectedIndexPaths = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Fetched results controller
/**
 *  The lazy loaded fetched results controller.
 *
 *  @return Existing or just initialized fetched results controller (fetching ordered active packs).
 */
-(NSFetchedResultsController *)frc
{
    if (_frc != nil) return _frc;
    
    // Configure the fetch request
    // (emus in active packs, divided to section by pack)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.package.isActive=%@", @NO, @YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    
    fetchRequest.sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.prioritizedIdentifier" ascending:NO]
                                     ];

    fetchRequest.fetchBatchSize = 20;

    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:@"emuDef.package.prioritizedIdentifier"
                                                                                     cacheName:@"emus by pack for feed"];
    _frc = frc;
    [_frc performFetch:nil];
    return _frc;
}

/**
 *  Reset, recreate and reperform fetch.
 */
-(void)reset
{
    _frc = nil;
    [self frc];
}

#pragma mark - Public questions about the data
-(NSString *)titleForSection:(NSInteger)section
{
    Emuticon *emu = [self.frc objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
    Package *pack = emu.emuDef.package;
    return pack.label;
}

-(NSString *)packOIDForSection:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    Package *pack = emu.emuDef.package;
    return pack.oid;
}

-(NSInteger)packsCount
{
    NSInteger count = self.frc.sections.count;
    _packsCount = count;
    return count;
}

-(NSIndexPath *)indexPathForPackOID:(NSString *)packOID
{
    for (NSInteger section=0; section<self.frc.sections.count;section++) {
        id<NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
        if ([sectionInfo numberOfObjects] < 1) continue;
        NSIndexPath *indexPath =[NSIndexPath indexPathForItem:0 inSection:section];
        Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
        if (emu == nil) continue;
        if ([emu.emuDef.package.oid isEqualToString:packOID]) return indexPath;
    }
    return nil;
}

#pragma mark - Private helpers
/**
 *  Array of all index paths of emus in a given section.
 *
 *  @param section NSInteger index of the section
 *
 *  @return An array of indexPaths for all emus in given section.
 */
-(NSArray *)indexPathsForSection:(NSInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    id<NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
    NSInteger emusCount = [sectionInfo numberOfObjects];
    for (NSInteger i=0;i<emusCount;i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

#pragma mark - UICollectionViewDataSource
/**
 *  Only one section (of packs).
 *
 *  @param collectionView The related collection view.
 *
 *  @return Currently, 1 section is hard coded.
 */
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.packsCount;
}

/**
 *  The number of emus in a pack/section.
 *
 *  @param collectionView related collection view.
 *  @param section        the section number.
 *
 *  @return The number of packs fetched by the fetched results controller.
 */
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
    return [sectionInfo numberOfObjects];
}

/**
 *  A cell for pack at index path.
 *
 *  @param collectionView related collection view.
 *  @param indexPath      related indexpath of cell/object.
 *
 *  @return Configured and updated EMPackCell for passed index path.
 */
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu cell";
    static NSString *originUI = @"feed";
    EMEmuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                 forIndexPath:indexPath];
    cell.inUI = originUI;
    
    // Get the emu object.
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    
    // Configure the cell with the emu object.
    if (self.failedOIDS[emu.oid]) {
        // Epic Fail!
        [cell updateStateToFailed];
    } else {
        // Configure the cell according to emu state.
        [cell updateStateWithEmu:emu forIndexPath:indexPath];

        // Further configuration according to data source state.
        cell.selectable = self.selectionsAllowed;
        cell.selected = [[self.selectedIndexPaths objectForKey:indexPath] isEqualToNumber:@YES];
    }
        
    // Update the cell UI according to current cell state.
    [cell updateGUI];
    
    return cell;
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath
{
    if (![kind isEqualToString:UICollectionElementKindSectionHeader]) return nil;
    
    static NSString *viewIdentifier = @"pack header";
    EMPackHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                      withReuseIdentifier:viewIdentifier
                                                                             forIndexPath:indexPath];

    // Configure
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    Package *pack = emu.emuDef.package;
    headerView.label = pack.label;
    headerView.sectionIndex = indexPath.section;
    
    // Update the UI
    [headerView updateGUI];
    
    return headerView;
}

#pragma mark - Selections
-(void)enableSelections
{
    _selectionsAllowed = YES;
}

-(void)disableSelections
{
    _selectionsAllowed = NO;
}

-(void)clearSelections
{
    [self.selectedIndexPaths removeAllObjects];
}

-(void)toggleSelectionForEmusAtSection:(NSInteger)section
{
    // Check if all emus selected already in this section.
    // If all selected, will unselect all.
    // If not all selected should selected all remaining unselected ones.
    NSArray *indexPaths = [self indexPathsForSection:section];
    BOOL shouldSelect = NO;
    for (NSIndexPath *indexPath in indexPaths) {
        // Iterate all emus in section, if at least one is unselected
        // mark all as need to be selected.
        if (self.selectedIndexPaths[indexPath] == nil) {
            shouldSelect = YES;
            break;
        }
    }
    
    if (shouldSelect) {
        // Select all emus in the pack related to the section.
        for (NSIndexPath *indexPath in indexPaths)
            [self selectEmuAtIndexPath:indexPath];
    } else {
        // Unselect all emus in the pack related to the section.
        for (NSIndexPath *indexPath in indexPaths)
            [self unselectEmuAtIndexPath:indexPath];
    }
}

-(void)selectEmuAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPaths[indexPath] = @YES;
}

-(void)unselectEmuAtIndexPath:(NSIndexPath *)indexPath;
{
    if (self.selectedIndexPaths[indexPath] == nil) return;
    [self.selectedIndexPaths removeObjectForKey:indexPath];
}

-(void)toggleSelectionForEmuAtIndexPath:(NSIndexPath *)indexPath;
{
    if (self.selectedIndexPaths[indexPath] == nil) {
        [self selectEmuAtIndexPath:indexPath];
    } else {
        [self unselectEmuAtIndexPath:indexPath];
    }
}

-(NSInteger)selectionsCount
{
    if (!self.selectionsAllowed) return 0;
    return self.selectedIndexPaths.count;
}

#pragma mark - Prioritize emus
-(void)preferEmusAtIndexPaths:(NSArray *)indexPaths
{
    [Emuticon enqueueRequiredDownloadsForIndexPaths:indexPaths
                                                frc:self.frc
                                              forUI:@"feed"];
}

@end
