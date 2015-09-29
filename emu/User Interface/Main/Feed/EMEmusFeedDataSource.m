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

@interface EMEmusFeedDataSource()

@property (nonatomic, readwrite) NSInteger packsCount;

// The fetched results controller.
@property (nonatomic) NSFetchedResultsController *frc;

@end

@implementation EMEmusFeedDataSource

-(id)init
{
    self = [super init];
    if (self) {
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
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"emuDef.package.isActive=%@", @YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.priority" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;

    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:@"emuDef.package.label"
                                                                                     cacheName:@"Emus"];
    _frc = frc;
    [_frc performFetch:nil];
    return _frc;
}

-(void)reset
{
    _frc = nil;
    [self frc];
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

-(NSInteger)packsCount
{
    NSInteger count = self.frc.sections.count;
    _packsCount = count;
    return count;
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
    EMEmuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                 forIndexPath:indexPath];
    
    // Get the emu object.
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    
    // Configure the cell with the emu object.
    [cell updateStateWithEmu:emu forIndexPath:indexPath];
    
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
    id<NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[indexPath.section];
    headerView.label = [sectionInfo name];
    
    
    // Update the UI
    [headerView updateGUI];
    
    return headerView;
}
  
@end
