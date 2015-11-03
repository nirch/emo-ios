//
//  EMBackend+AppStore.h
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMBackend.h"

@interface EMBackend (AppStore)<
    SKProductsRequestDelegate,
    SKPaymentTransactionObserver
>

/**
 *  Refreshes all products info from app store to local storage.
 */
-(void)storeRefreshProductsInfo;
-(void)refreshProductInfoForPack:(Package *)package;
-(void)refreshInfoForPacksWithProductsPIDS:(NSSet *)premiumPIDS;
-(void)buyProductWithIdentifier:(NSString *)productIdentifier;

@end
