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
    NSMutableDictionary *productsInfo = [NSMutableDictionary new];
    for (SKProduct *product in response.products) {
        self.productsByPID[product.productIdentifier] = product;
    }

    // Update packs by product info.
    NSArray *premiumPacks = [Package allPremiumPackagesInContext:EMDB.sh.context];
    for (Package *package in premiumPacks) {
        SKProduct *product = self.productsByPID[package.hdProductID];
        if (product != nil && product.productIdentifier != nil) {
            self.packOIDByPID[product.productIdentifier] = package.oid;
            package.hdProductValidated = @YES;
            package.hdPriceLabel = [self priceAsStringForProduct:product];
            package.productTitle = [product localizedTitle];
            package.productDescription = [product localizedDescription];
            productsInfo[product.productIdentifier] = [self infoForProduct:product withPackage:package];
        } else {
            package.hdProductValidated = @NO;
        }
        
        HMLOG(TAG, EM_DBG, @"Updating product info: %@", [product description]);
    }
    
    // Notify the user interface about the updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsInfoUpdated object:nil userInfo:productsInfo];
}

-(NSDictionary *)infoForProduct:(SKProduct *)product withPackage:(Package *)package
{
    HMParams *info = [HMParams new];
    [info addKey:AK_EP_PRODUCT_ID valueIfNotNil:product.productIdentifier];
    [info addKey:AK_EP_PRODUCT_NAME valueIfNotNil:package.name];
    [info addKey:AK_EP_PRODUCT_TYPE valueIfNotNil:emkProductTypeHDPackage]; // Hard coded for now. More options in the future.
    [info addKey:AK_EP_PRICE valueIfNotNil:product.price];
    [info addKey:AK_EP_CURRENCY value:[product.priceLocale objectForKey:NSLocaleCurrencyCode]];
    return info.dictionary;
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
    BOOL anyTransactionSuccessful = NO;
    NSInteger restoredCount = 0;
    
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
                [self transactionWithIdentifier:productIdentifier success:YES restored:NO error:nil];
                finishedAnyTransaction = YES;
                anyTransactionSuccessful = YES;
                break;
            case SKPaymentTransactionStateFailed:
                //
                //  Failed / Canceled
                //
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self transactionWithIdentifier:productIdentifier success:NO restored:NO error:transaction.error];
                finishedAnyTransaction = YES;
                break;
            case SKPaymentTransactionStateRestored:
                //
                //  Product Restored
                //
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self transactionWithIdentifier:productIdentifier success:YES restored:YES error:nil];
                finishedAnyTransaction = YES;
                restoredCount++;
                break;
            default:
                break;
        }
    }

    // Notify the user interface about the transactions.
    if (finishedAnyTransaction) {
        if (restoredCount > 0) {
            NSDictionary *info = @{@"restoredCount":@(restoredCount)};
            [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsRestoredPurchases object:nil userInfo:info];
        } else {
            NSDictionary *info = @{@"anyTransactionSuccessful":@(anyTransactionSuccessful)};
            [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsHandledTransactions object:nil userInfo:info];
        }
    }
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    HMParams *info = [HMParams new];
    [info addKey:@"error" valueIfNotNil:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsError object:nil userInfo:info.dictionary];
}


-(void)transactionWithIdentifier:productIdentifier
                         success:(BOOL)success
                        restored:(BOOL)restored
                           error:(NSError *)error
{
    NSString *packOID = self.packOIDByPID[productIdentifier];
    if (packOID == nil) return;
    Package *package = [Package findWithID:packOID context:EMDB.sh.context];
    if (package == nil) return;
    
    if (success) {
        // Unlock hd for this pack.
        package.hdUnlocked = @YES;
    }
    
    // Analytics
    SKProduct *product = self.productsByPID[productIdentifier];
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PRODUCT_TYPE valueIfNotNil:emkProductTypeHDPackage]; // Hard coded for now. More product types in the future.
    [params addKey:AK_EP_PRODUCT_ID valueIfNotNil:productIdentifier];
    [params addKey:AK_EP_PRODUCT_NAME valueIfNotNil:package.name];
    [params addKey:AK_EP_PRICE valueIfNotNil:product.price.stringValue];
    [params addKey:AK_EP_CURRENCY valueIfNotNil:[product.priceLocale objectForKey:NSLocaleCurrencyCode]];
    [params addKey:AK_EP_SUCCESS value:@(success)];
    [params addKey:AK_EP_RESTORED_PURCHASE value:@(restored)];
    [params addKey:AK_EP_ERROR_DESCRIPTION valueIfNotNil:[error localizedDescription]];
    [HMPanel.sh analyticsEvent:AK_E_IAP_TRANSACTION info:params.dictionary];
}

#pragma mark - Restore
-(void)restorePurchases
{
    if (!self.isAlreadyListeningToTransactions) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.isAlreadyListeningToTransactions = YES;
    }
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Clean up
-(void)cleanup
{
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;
}

@end
