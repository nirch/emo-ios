//
//  EMEmusPickerDataSource.m
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//
#define TAG @"EMEmusPickerDataSource"


#import "EMEmusPickerDataSource.h"
#import "EMDB.h"
#import "EMEmuCell.h"
#import "Emuticon+DownloadsHelpers.h"

@interface EMEmusPickerDataSource()

@property (nonatomic, readonly) NSFetchedResultsController *frc;

@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) NSInteger limit;
@property (nonatomic, readonly) NSInteger minimumCellsCount;

@end

@implementation EMEmusPickerDataSource

@synthesize frc = _frc;
@synthesize predicate = _predicate;
@synthesize sortDescriptors = _sortDescriptors;
@synthesize limit = _limit;


-(instancetype)initWithPredicate:(NSPredicate *)predicate
                          sortBy:(NSArray *)sortBy
                           limit:(NSNumber *)limit
               minimumCellsCount:(NSNumber *)minimumCellsCount;
{
    self = [super init];
    if (self) {
        [self configureFRCWithPredicate:predicate
                                 sortBy:sortBy
                                  limit:limit];
        _minimumCellsCount = minimumCellsCount?minimumCellsCount.integerValue:0;
    }
    return self;
}

/**
 *  Recreates the fetched results controller.
 *  (with last configured predicate, sort descriptors and limit configuration)
 *  Performs fetch.
 */
-(void)resetFRC
{
    _frc = nil;
    NSError *error;
    [self.frc performFetch:&error];
    if (error) {
        HMLOG(TAG, EM_ERR, @"Error on perform fetch. %@", [error description]);
    }
}

-(NSFetchedResultsController *)frc
{
    if (_frc != nil) return _frc;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = self.predicate;
    fetchRequest.sortDescriptors = self.sortDescriptors;
    fetchRequest.fetchLimit = _limit;
    _frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:EMDB.sh.context
                                                 sectionNameKeyPath:nil
                                                          cacheName:nil];
    return _frc;
}

-(void)configureFRCWithPredicate:(NSPredicate *)predicate
                          sortBy:(NSArray *)sortBy
                           limit:(NSNumber *)limit
{
    _predicate = predicate;
    _sortDescriptors = sortBy?sortBy:@[ [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ];
    _limit = limit?limit.integerValue:0;
}

#pragma mark - Public data
-(NSString *)emuticonOIDAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isIndexPathOutOfBounds:indexPath]) return nil;
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    return emu.oid;
}

-(NSInteger)emusCount
{
    return self.frc.fetchedObjects.count;
}


-(BOOL)isIndexPathOutOfBounds:(NSIndexPath *)indexPath
{
    if (indexPath.item>=self.frc.fetchedObjects.count) return YES;
    return NO;
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return MAX(self.frc.fetchedObjects.count, self.minimumCellsCount);
}

/**
 *  A cell for emu at index path.
 *
 *  @param collectionView related collection view.
 *  @param indexPath      related indexpath of cell/object.
 *
 *  @return Configured and updated EMEmuCell for passed index path.
 */
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu picker cell";
    static NSString *originUI = @"EmusPicker";
    EMEmuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                forIndexPath:indexPath];
    cell.inUI = originUI;
    
    // Ensure we in the bounds of the available fetched data.
    if (indexPath.item >= self.frc.fetchedObjects.count) {
        // Data unavailable at this index path. This is an empty cell.
        [cell updateStateToEmpty];
        [cell updateGUI];
        return cell;
    }
    
    // Get the emu object.
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    
    // Configure the cell with the emu object.
    if (self.failedOIDS[emu.oid]) {
        // Epic Fail!
        [cell updateStateToFailed];
    } else {
        // Configure the cell according to emu state.
        [cell updateStateWithEmu:emu forIndexPath:indexPath];
    }
    
    // Update the cell UI according to current cell state.
    [cell updateGUI];
    
    return cell;
}

#pragma mark - Prioritize emus
-(void)preferEmusAtIndexPaths:(NSArray *)indexPaths
{
    [Emuticon enqueueRequiredDownloadsForIndexPaths:indexPaths
                                                frc:self.frc
                                              forUI:@"emus picker"];
}

@end
