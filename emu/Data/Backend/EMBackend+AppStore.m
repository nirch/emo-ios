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
#import "AppManagement.h"

@interface EMBackend()

@end

@implementation EMBackend (AppStore)

-(void)initProductsInfo
{
    if (self.productsInfo) return;
    
    self.productsInfo = [NSMutableDictionary new];
    self.productsOrderedPID = [NSMutableArray new];
    
    // In app purchase products list.
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"StoreProducts" ofType:@"plist"];
    NSDictionary *productsLists = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *productsInfo = nil;
    if (AppManagement.sh.isTestApp) {
        productsInfo = productsLists[@"test"];
    } else {
        productsInfo = productsLists[@"production"];
    }
    
    for (NSDictionary *productInfo in productsInfo) {
        NSString *pid = productInfo[@"pid"];
        self.productsInfo[pid] = [NSMutableDictionary dictionaryWithDictionary:productInfo];
        [self.productsOrderedPID addObject:pid];
        
        // If product is related to a feature.
        if (productInfo[@"related_feature_oid"]) {
            NSString *oid = productInfo[@"related_feature_oid"];
            Feature *feature = [Feature findOrCreateWithOID:oid context:EMDB.sh.context];
            feature.pid = pid;
        }
    }
    [EMDB.sh save];
}

-(void)storeRefreshProductsInfo
{
    if (self.productsInfo == nil) {
        [self initProductsInfo];
    }
    NSSet *pidsSet = [NSSet setWithArray:self.productsOrderedPID];
    [self refreshInfoForItemsWithProductsPIDS:pidsSet];
}

-(void)refreshProductInfoForPack:(Package *)package
{
//    [self refreshInfoForPacksWithProductsPIDS:[NSSet setWithArray:@[package.hdProductID]]];
}

-(void)refreshInfoForItemsWithProductsPIDS:(NSSet *)pids
{
    // Ignore request if currently handling a request/response.
    if (self.productsRequest) return;
    
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:pids];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

-(void)buyProductWithIdentifier:(NSString *)productIdentifier
{
    NSDictionary *info = self.productsInfo[productIdentifier];
    SKProduct *product = info[@"productObject"];
    if (product == nil) {
        return;
    }
    
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
    // Products.
    for (SKProduct *product in response.products) {
        NSString *pid = product.productIdentifier;
        if (self.productsInfo[pid] == nil) continue;
        
        NSMutableDictionary *productInfo = self.productsInfo[pid];
        
        HMParams *info = [HMParams new];
        [info addKey:@"valid" value:@YES];
        [info addKey:@"productTitle" valueIfNotNil:[product localizedTitle]];
        [info addKey:@"priceLabel" valueIfNotNil:[self priceAsStringForProduct:product]];
        [info addKey:@"productDescription" valueIfNotNil:[product localizedDescription]];
        [info addKey:@"productObject" value:product];
        [productInfo addEntriesFromDictionary:info.dictionary];
    }
    
    // Invalid products.
    for (NSString *invalidPID in response.invalidProductIdentifiers) {
        if (self.productsInfo[invalidPID] == nil) continue;
        
        NSMutableDictionary *productInfo = self.productsInfo[invalidPID];
        productInfo[@"valid"] = @NO;
    }

    // Notify the user interface about the updates.
    [self cleanup];
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsInfoUpdated object:nil userInfo:nil];
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    HMParams *info = [HMParams new];
    [info addKey:@"error" valueIfNotNil:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataProductsError object:nil userInfo:info.dictionary];
    [self cleanup];
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
    [self cleanup];
}


-(void)transactionWithIdentifier:productIdentifier
                         success:(BOOL)success
                        restored:(BOOL)restored
                           error:(NSError *)error
{
    HMLOG(TAG,
          EM_DBG,
          @"Transaction with ID:%@ success:%@ restore:%@ error:%@",
          productIdentifier,
          @(success),
          @(restored),
          [error description]);
    
    NSDictionary *info = self.productsInfo[productIdentifier];
    SKProduct *product = info[@"productObject"];
    Feature *feature = [Feature findWithPID:productIdentifier context:EMDB.sh.context];
    if (feature == nil || success == NO || error != nil) return;
    
    // Unlock the feature.
    feature.purchased = @YES;
    [EMDB.sh save];
    
    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PRODUCT_TYPE valueIfNotNil:emkProductTypeUnlockFeature]; // Hard coded for now. More product types in the future.
    [params addKey:AK_EP_PRODUCT_ID valueIfNotNil:productIdentifier];
    [params addKey:AK_EP_PRODUCT_NAME valueIfNotNil:feature.oid];
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
