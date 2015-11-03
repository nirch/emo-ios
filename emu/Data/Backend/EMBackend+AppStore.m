//
//  EMBackend+AppStore.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#define TAG @"EMBackend(AppStore)"

#import "EMBackend+AppStore.h"
#import "EMDB.h"
#import "EMNotificationCenter.h"

@interface EMBackend()

@end

@implementation EMBackend (AppStore)

-(void)storeRefreshProductsInfo
{
    // List of packages with hd product id.
    NSMutableSet *premiumPIDS = [NSMutableSet new];
    NSArray *premiumPacks = [Package allPremiumPackagesInContext:EMDB.sh.context];
    for (Package *package in premiumPacks) {
        if (package.hdProductID) {
            [premiumPIDS addObject:package.hdProductID];
        }
    }
    [self refreshInfoForPacksWithProductsPIDS:premiumPIDS];
}

-(void)refreshProductInfoForPack:(Package *)package
{
    [self refreshInfoForPacksWithProductsPIDS:[NSSet setWithArray:@[package.hdProductID]]];
}

-(void)refreshInfoForPacksWithProductsPIDS:(NSSet *)premiumPIDS
{
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:premiumPIDS];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

-(void)buyProductWithIdentifier:(NSString *)productIdentifier
{
    // Ensure product is relevant.
    SKProduct *product = self.productsByPID[productIdentifier];
    if (product == nil) return;
    
    // Listen to transactions if not already listening
    if (!self.isAlreadyListeningToTransactions) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.isAlreadyListeningToTransactions = YES;
    }
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKProductsRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (self.productsByPID == nil) self.productsByPID = [NSMutableDictionary new];
    if (self.packOIDByPID == nil) self.packOIDByPID = [NSMutableDictionary new];
    
    // Products.
    for (SKProduct *product in response.products) {
        self.productsByPID[product.productIdentifier] = product;
    }

    // Update packs by product info.
    NSArray *premiumPacks = [Package allPremiumPackagesInContext:EMDB.sh.context];
    for (Package *package in premiumPacks) {
        SKProduct *product = self.productsByPID[package.hdProductID];
        self.packOIDByPID[product.productIdentifier] = package.oid;
        if (product) {
            package.hdProductValidated = @YES;
            package.hdPriceLabel = [self priceAsStringForProduct:product];
            package.productTitle = [product localizedTitle];
            package.productDescription = [product localizedDescription];
        } else {
            package.hdProductValidated = @NO;
        }
        HMLOG(TAG, EM_DBG, @"Updating product info: %@", [product description]);
    }
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsInfoUpdated object:nil userInfo:nil];
}

-(NSString *)priceAsStringForProduct:(SKProduct *)product
{
    if ([[product price] isEqualToNumber:@0]) {
        return LS(@"FREE");
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[product priceLocale]];
    NSString *str = [formatter stringFromNumber:[product price]];
    return str;
}


#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    BOOL finishedAnyTransaction = NO;
    for (SKPaymentTransaction * transaction in transactions) {
        // Gather some info about this transaction.
        NSString *productIdentifier = transaction.payment.productIdentifier;
        
        // Handle transaction states.
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                //
                //  Purchased
                //
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self purchasedProductWithIdentifier:productIdentifier];
                finishedAnyTransaction = YES;
                break;
            case SKPaymentTransactionStateFailed:
                //
                //  Failed / Canceled
                //
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                finishedAnyTransaction = YES;
                break;
            case SKPaymentTransactionStateRestored:
                //
                //  Product Restored
                //
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self purchasedProductWithIdentifier:productIdentifier];
                finishedAnyTransaction = YES;
                break;
            default:
                break;
        }
    }

    // Notify the user interface about the transactions.
    if (finishedAnyTransaction)
        [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsHandledTransactions object:nil userInfo:nil];
}

-(void)purchasedProductWithIdentifier:productIdentifier
{
    NSString *packOID = self.packOIDByPID[productIdentifier];
    if (packOID == nil) return;
    Package *package = [Package findWithID:packOID context:EMDB.sh.context];
    if (package == nil) return;
    
    // Unlock hd for this pack.
    package.hdUnlocked = @YES;
}


#pragma mark - Clean up
-(void)cleanup
{
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;
}

@end
