//
//  EMFootagesDataSource.m
//  emu
//
//  Created by Aviv Wolf on 10/10/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFootagesDataSource.h"
#import "EMFootageCell.h"
#import "EMDB.h"

@interface EMFootagesDataSource()

@property (nonatomic, readonly) NSFetchedResultsController *frc;
@property (nonatomic, readonly) NSString *masterFootageOID;

@end

@implementation EMFootagesDataSource

@synthesize frc = _frc;

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.remoteFootages = NO;
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_USER_FOOTAGE];
    fetchRequest.sortDescriptors = @[
                                      [NSSortDescriptor sortDescriptorWithKey:@"timeTaken" ascending:NO]
                                     ];
    fetchRequest.fetchBatchSize = 20;
    
    // Predicates
    NSMutableArray *predicates = [NSMutableArray new];
    
    // Remote / Local footages.
    [predicates addObject:[NSPredicate predicateWithFormat:@"remoteFootage=%@", self.remoteFootages?@YES:@NO]];

    // HD Footages only?
    if (self.hdFootagesOnly) [predicates addObject:[UserFootage predicateForHD]];
    
    // Never show dedicated footages.
    [predicates addObject:[NSPredicate predicateWithFormat:@"duration<=%@",@2]];
    
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    _frc = frc;
    [_frc performFetch:nil];
    _masterFootageOID = [UserFootage masterFootage].oid;
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

#pragma mark - Data source
/**
 *  The number of footages.
 *
 *  @param collectionView related collection view.
 *  @param section        the section number.
 *
 *  @return NSInteger with the number of footages.
 */
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = MAX(18, self.footagesCount);
    if (count % 3 != 0) count += 3 - (count%3);
    return count;
}

/**
 *  Configuring a cell for pack at index path.
 *
 *  @param collectionView related collection view.
 *  @param indexPath      related indexpath of cell/object.
 *
 *  @return Configured and updated EMPackCell for passed index path.
 */
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"footage cell";
    EMFootageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                 forIndexPath:indexPath];

    UserFootage *footage = nil;
    if (indexPath.item < [self footagesCount]) {
        footage = [self.frc objectAtIndexPath:indexPath];
    }
    [cell updateStateWithFootage:footage];
    cell.isDefault = [footage.oid isEqualToString:self.masterFootageOID];
    cell.isHD = [footage isHD];
    
    // Update the cell UI
    [cell updateGUI];
    
    return cell;
}

#pragma mark - Selections
-(void)selectIndexPath:(NSIndexPath *)indexPath
      inCollectionView:(UICollectionView *)collectionView
{
    if (indexPath.item >= [self footagesCount]) return;
    
    // First deselect a previous cell, if selected
    if (self.selectedIndexPath) {
        NSIndexPath *indexPath = _selectedIndexPath;
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        _selectedIndexPath = nil;
    }
    
    _selectedIndexPath = indexPath;
    EMFootageCell *cell = (EMFootageCell *)[collectionView cellForItemAtIndexPath:indexPath];
    UserFootage *footage = [self.frc objectAtIndexPath:indexPath];
    [cell startPlayingFootage:footage];
}

-(NSString *)selectedFootageOID
{
    if (self.selectedIndexPath.item >= [self footagesCount]) return nil;
    UserFootage *footage = [self.frc objectAtIndexPath:self.selectedIndexPath];
    return footage.oid;
}

#pragma mark - Public data
-(NSInteger)footagesCount
{
    return self.frc.fetchedObjects.count;
}

-(void)unselect
{
    _selectedIndexPath = nil;
}

@end
