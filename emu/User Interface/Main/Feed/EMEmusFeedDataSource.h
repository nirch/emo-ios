//
//  EMEmusFeedDataSource.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@import UIKit;

@interface EMEmusFeedDataSource : NSObject<
    UICollectionViewDataSource
>

/**
 *  The number of active packs / sections.
 */
@property (nonatomic, readonly) NSInteger packsCount;

/**
 *  Resets the fetched results controller in reperforms the fetch using the context.
 */
-(void)reset;

#pragma mark - Public data info
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


@end
