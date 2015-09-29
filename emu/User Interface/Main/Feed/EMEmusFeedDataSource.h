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

-(void)reset;

@end
