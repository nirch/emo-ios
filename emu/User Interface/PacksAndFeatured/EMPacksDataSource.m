//
//  EMPacksDataSource.m
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMPacksDataSource.h"
#import "EMPackCell.h"
#import "EMDB.h"

@interface EMPacksDataSource()

@property (nonatomic, readwrite) NSInteger packsCount;
@property (nonatomic, readwrite) NSInteger lastWidePack;

@property (nonatomic) NSFetchedResultsController *frc;

@end

@implementation EMPacksDataSource

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
    // (active packs, ordered by priority)
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND (isHidden=nil OR isHidden=%@)", @YES, @NO];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"prioritizedIdentifier" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil]; // @"Root"
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
 *  The number of packs.
 *
 *  @param collectionView related collection view.
 *  @param section        the section number.
 *
 *  @return The number of packs fetched by the fetched results controller.
 */
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    self.lastWidePack = (self.packsCount%2==0)?2:3;
    return self.packsCount;
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
    static NSString *cellIdentifier = @"pack cell";
    EMPackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                 forIndexPath:indexPath];
    // Get the pack
    Package *pack = [self.frc objectAtIndexPath:indexPath];
    
    // Configure the cell using info about the pack
    BOOL isBanner = indexPath.item < self.lastWidePack;
    cell.iconURL = isBanner? nil:[pack urlForPackageIcon];
    cell.label = pack.label;
    cell.bannerURL = isBanner ? [pack urlForPackageBannerWide] : nil;
    cell.isBanner = isBanner;
    cell.indexTag = indexPath.item;
    
    // Update the cell UI
    [cell updateGUI];

    return cell;
}

#pragma mark - Public info about the data
-(NSIndexPath *)indexPathByPackOID:(NSString *)packOID
{
    NSInteger i = 0;
    // TODO: check this. Currently O(n). Can it be done in O(1)?
    for (Package *pack in self.frc.fetchedObjects) {
        if ([pack.oid isEqualToString:packOID]) {
            return [NSIndexPath indexPathForItem:i inSection:0];
        }
        i++;
    }
    return nil;
}

-(NSString *)packOIDByIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section>0) return nil;
    if (indexPath.item>=self.frc.fetchedObjects.count) return nil;
    Package *pack = [self.frc objectAtIndexPath:indexPath];
    return pack.oid;
}

-(NSInteger)packsCount
{
    NSInteger count = self.frc.fetchedObjects.count;
    _packsCount = count;
    return count;
}


@end
