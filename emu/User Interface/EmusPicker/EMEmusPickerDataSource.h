//
//  EMEmusPickerDataSource.h
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface EMEmusPickerDataSource : NSObject<
    UICollectionViewDataSource
>

#pragma mark - Initializer
/**
 *  Initializes the data source and configures the frc.
 *
 *  @param predicate            (optional) NSPredicate (default returns all emus)
 *  @param sortBy               (optional) NSArray of sort descriptors (default sorts by oid)
 *  @param limit                (optional) NSNumber for limiting number of results (default - no limit)
 *  @param minimumCellsCount    (optional) NSNumber minimum number of cells to dislay. If content has less
 *                                         than the given number, empty cells will be displayed up to the minimum
 *                                         provided. (default is 0 so no empty cells will be displayed).
 *
 *  @return New instance of EMEmusPickerDataSource
 */
-(instancetype)initWithPredicate:(NSPredicate *)predicate
                          sortBy:(NSArray *)sortBy
                           limit:(NSNumber *)limit
               minimumCellsCount:(NSNumber *)minimumCellsCount;


#pragma mark - Fetched results controller
/**
 *  Recreates the fetched results controller.
 *  (with last configured predicate, sort descriptors and limit configuration)
 *  Performs fetch.
 */
-(void)resetFRC;

/**
 *  Factory for the common fetched results controller used by this data source.
 *  Will configure and return a fetched results controller of a fetch request
 *  fetching emus from the db.
 *
 *  Stores the configuration internally and call resetFRC
 *
 *  @param predicate (optional) NSPredicate (default returns all emus)
 *  @param sortBy    (optional) NSArray of sort descriptors (default sorts by oid)
 *  @param limit     (optional) NSNumber for limiting number of results (default - no limit)
 *
 */
-(void)configureFRCWithPredicate:(NSPredicate *)predicate
                          sortBy:(NSArray *)sortBy
                           limit:(NSNumber *)limit;


#pragma mark - Public data
/**
 *  The oid of the emuticon at given index path.
 *
 *  @param indexPath Index path
 *
 *  @return oid of the Emuticon at index path. If index path out of bounds, will return nil.
 */
-(NSString *)emuticonOIDAtIndexPath:(NSIndexPath *)indexPath;


/**
 *  The number of emus in the collection.
 *
 *  @return NSInteger with the number of emus in the collection.
 */
-(NSInteger)emusCount;

/**
 *  The apect ratio of the emu found at given indexPath
 *
 *  @param indexPath NSIndexPath of the emu
 *
 *  @return CGFloat value of the aspect ratio (width/height)
 */
-(CGFloat)aspectRatioAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Emus
-(void)preferEmusAtIndexPaths:(NSArray *)indexPaths;

/**
 *  A dictionary of failed emus by oid.
 */
@property (nonatomic, readonly) NSMutableDictionary *failedOIDS;


@end
