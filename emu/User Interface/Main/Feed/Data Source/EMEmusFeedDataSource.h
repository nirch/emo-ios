//
//  EMEmusFeedDataSource.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@import UIKit;

@class Package;

@interface EMEmusFeedDataSource : NSObject<
    UICollectionViewDataSource
>


/**
 *  A dictionary of failed emus by oid.
 */
@property (nonatomic, readonly) NSMutableDictionary *failedOIDS;

/**
 *  The number of active packs / sections.
 */
@property (nonatomic, readonly) NSInteger packsCount;

/**
 *  Resets the fetched results controller in reperforms the fetch using the context.
 */
-(void)reset;

#pragma mark - Selections
@property (nonatomic, readonly) BOOL selectionsAllowed;

/**
 *  Allow selecting emus. (shows selection indicators)
 */
-(void)enableSelections;

/**
 *  Don't allow selecting emus. (hides selection indicators)
 */
-(void)disableSelections;

/**
 *  Remove all current selections.
 */
-(void)clearSelections;

/**
 *  Selects an emu at index path.
 *
 *  @param indexPath the index path of the Emu in current data source.
 */
-(void)selectEmuAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Unselects an emu at index path.
 *
 *  @param indexPath the index path of the Emu in current data source.
 */
-(void)unselectEmuAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Toggles selected/unselected for an emu at index path.
 *
 *  @param indexPath the index path of the Emu in current data source.
 */
-(void)toggleSelectionForEmuAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  If not all emus are selected for the pack in given section then
 *  will select all the emus in that pack/section.
 *  Otherwise will unselect all the emus in that pack/section.
 *
 *  @param section The index of the section of the pack.
 */
-(void)toggleSelectionForEmusAtSection:(NSInteger)section;

/**
 *  The number of emus selected.
 *  Will return 0 if not in selections state.
 *
 *  @return NSInteger of the number of emus selected.
 */
-(NSInteger)selectionsCount;


/**
 *  Return an array of NSString OID of emus selected.
 *
 *  @return NSArray of NSStrings with OIDs of selected emus.
 */
-(NSArray *)selectionsOID;

#pragma mark - Public data info
/**
 *  Return the pack related to a given section index.
 *
 *  @param section The section index.
 *
 *  @return The Package object.
 */
-(Package *)packForSection:(NSInteger)section;

/**
 *  Return the pack OID related to a given section index.
 *
 *  @param section The section index.
 *
 *  @return The pack oid as NSString.
 */
-(NSString *)packOIDForSection:(NSInteger)section;

/**
 *  Return an index path for a section related to the passed pack oid.
 *
 *  @param packOID The related pack oid.
 *
 *  @return NSIndexPath pointing to the section of the found pack (nil if not found).
 */
-(NSIndexPath *)indexPathForPackOID:(NSString *)packOID;

/**
 *  Return the title (pack label) for section number.
 *
 *  @param section NSInteger number of the section.
 *
 *  @return NSString with the title of the section (nil if such section doesn't exist).
 */
-(NSString *)titleForSection:(NSInteger)section;

/**
 *  The number of emus in the section at provided section index
 *
 *  @param section NSInteger The section index.
 *
 *  @return NSInteger of the number of emus in that section.
 */
-(NSInteger)numberOfObjectsForSection:(NSInteger)section;

/**
 *  Emuticon oid at provided index path.
 *
 *  @param indexPath The indexPath of the object in the fetched results controller results.
 *
 *  @return NSString of the emu's oid (nil if not found).
 */
-(NSString *)emuOIDAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Prioritize emus
-(void)preferEmusAtIndexPaths:(NSArray *)indexPaths;

@end
