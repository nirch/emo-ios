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
    predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;

    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Root"];
    _frc = frc;
    [_frc performFetch:nil];
    return _frc;
}

-(void)reset
{
    _frc = nil;
}

#pragma mark - UICollectionViewDataSource
///**
// *  Only one section (of packs).
// *
// *  @param collectionView The related collection view.
// *
// *  @return Currently, 1 section is hard coded.
// */
//-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
//{
//    return 1;
//}

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
    self.packsCount = self.frc.fetchedObjects.count;
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
    cell.label = pack.label;
    cell.bannerURL = indexPath.item >= self.lastWidePack? [pack urlForPackageBanner] : [pack urlForPackageBannerWide];
    
    // Update the cell UI
    [cell updateGUI];

    return cell;
}

@end
