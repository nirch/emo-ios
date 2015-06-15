//
//  EMFeedDataSource.m
//  emu
//
//  Created by Aviv Wolf on 6/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFeedDataSource.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"
#import "EMFeedCell.h"

@interface EMFeedDataSource()

@property (nonatomic) NSFetchedResultsController *frc;

@end

@implementation EMFeedDataSource

-(void)refreshData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                        object:self
                                                      userInfo:nil];
}

-(void)reloadLocalData
{
    NSError *error;
    [self.frc performFetch:&error];
}

#pragma mark - NSFetchedResultsController
// Three possible fetched results controller are possible
// 1) Normal:           All emus available locally bunched in packs. (many sections)
// 2) Mixed Screen:     A list of specific mixed emus from several packs. (single section)
// 3) Search results:   A list of emus corresponding to a search.
-(NSFetchedResultsController *)frc
{
    if (_frc != nil) return _frc;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package" ascending:YES]
                                     ];
    NSFetchedResultsController *f = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:EMDB.sh.context
                                                                          sectionNameKeyPath:@"emuDef.package"
                                                                                   cacheName:nil];
    
    f.delegate = self;
    _frc = f;
    NSError *error;
    [_frc performFetch:&error];
    if (error) {
        // TODO: critical error handling.
    }
    
    return f;
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.frc.sections.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo>sectionInfo = self.frc.sections[section];
    return [sectionInfo numberOfObjects];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Dequeue the cell.
    static NSString *cellIdentifier = @"emu cell";
    EMFeedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    // Update the cell using the emu info.
    Emuticon *emu = [self.frc objectAtIndexPath:indexPath];
    [cell updateCellForEmu:emu info:@{
                                      emkEmuticonOID:emu.oid,
                                      emkEmuticonDefOID:emu.emuDef.oid,
                                      emkEmuticonDefName:emu.emuDef.name,
                                      emkIndexPath:indexPath
                                     }];
    // Return the cell.
    return cell;
}

@end
