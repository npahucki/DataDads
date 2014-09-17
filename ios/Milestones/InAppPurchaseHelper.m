//
// Created by Nathan  Pahucki on 9/11/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <objc/runtime.h>
#import "InAppPurchaseHelper.h"
#import "RMStore.h"
#import "RMAppReceipt.h"

static NSDictionary *productInfoForProduct(DDProduct product) {
    static NSArray *productCodes;
    if (!productCodes) {
        productCodes = @[
                @{@"id" : @"none"},
                @{@"id" : @"com.dataparenting.ad_removal", @"type" : @(DDProductSalesTypeOneTime)},
                @{@"id" : @"com.dataparenting.video_1", @"type" : @(DDProductSalesTypeSubscription)}];
    }
    return productCodes[product];
}


@implementation InAppPurchaseHelper {
    NSMutableDictionary *_paymentRequestCallbacks; // Naughty apple does not use the same SKPayment object, so we need to track blocks here.
    NSMutableDictionary *_productCache;
    RMAppReceipt *_appReceipt;

}


+ (InAppPurchaseHelper *)instance {
    static InAppPurchaseHelper *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _paymentRequestCallbacks = [[NSMutableDictionary alloc] init];
        _productCache = [[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}


- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)checkAdFreeProductPurchased:(PFBooleanResultBlock)block {
    [self checkProductsPurchased:@[@(DDProductAdRemoval), @(DDProductVideoSupport)] withBlock:block];
}

- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block {
    if ([self verifyAppReceipt]) {
        if ([self checkProductsPurchased:@[@(product)]]) {
            block(YES, nil); // Already purchased
        } else {
            if ([SKPaymentQueue canMakePayments]) {
                NSString *productId = productInfoForProduct(product)[@"id"];
                [self purchaseProduct:productId withBlock:block];
            } else {
                [UsageAnalytics trackAccountThatCantPurchase];
                [[[UIAlertView alloc] initWithTitle:@"Can Not Make Purchases" message:@"Your account is currently not allowed to make purchases." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                block(NO, nil);
            }
        }
    } else {
        // Apple recommends refresh if receipt validation fails.
        [[RMStore defaultStore] refreshReceiptOnSuccess:^{
            [self ensureProductPurchased:product withBlock:block];
        }                                       failure:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Connect to AppStore" message:@"Unable to verify your purchases at this moment. Please try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            [UsageAnalytics trackError:error forOperationNamed:@"RMStore.refreshReceipt"];
            block(NO, error);
        }];
    }
}

- (BOOL)verifyAppReceipt {
#if DISABLEIAP
    return YES;
#endif
    if (!_appReceipt) _appReceipt = [RMAppReceipt bundleReceipt];
    return [self verifyAppReceipt:_appReceipt];
}

- (BOOL)verifyAppReceipt:(RMAppReceipt *)receipt {
    if (!receipt) return NO;
    if (![receipt.bundleIdentifier isEqualToString:@"com.dataparenting.DataParenting"]) return NO;
    if (![receipt.appVersion isEqualToString:[[NSBundle mainBundle] infoDictionary][(NSString *) kCFBundleVersionKey]]) return NO;
    return [receipt verifyReceiptHash];
}

// If any of the products is purchased, then the block is called with YES.
- (void)checkProductsPurchased:(NSArray *)products withBlock:(PFBooleanResultBlock)block {
    if ([self verifyAppReceipt]) {
        BOOL purchased = [self checkProductsPurchased:products];
        block(purchased, nil);
    } else {
        // Apple recommends refresh if receipt validation fails.
        [[RMStore defaultStore] refreshReceiptOnSuccess:^{
            [self checkProductsPurchased:products withBlock:block];
        }                                       failure:^(NSError *error) {
            block(NO, error);
        }];
    }
}

// Call this method only after app receipt has been verified!
// Accepts an array of product numbers, returns true if any of the products is valid.
- (BOOL)checkProductsPurchased:(NSArray *)products {
#if DISABLEIAP
    return YES;
#endif

    NSAssert([self verifyAppReceipt], @"Expected App reciept to be verified already!");

    for (NSNumber *productIdNumber in products) {
        DDProduct product = (DDProduct) [productIdNumber unsignedIntegerValue];
        NSDictionary *productInfo = productInfoForProduct(product);
        NSString *productId = productInfo[@"id"];
        DDProductSalesType salesType = (DDProductSalesType) [(NSNumber *) productInfo[@"type"] unsignedIntegerValue];

        if (salesType == DDProductSalesTypeSubscription) {
            if ([_appReceipt containsActiveAutoRenewableSubscriptionOfProductIdentifier:
                    productId                                                   forDate:[NSDate date]]) {
                return YES;
            }
        } else {
            if ([_appReceipt containsInAppPurchaseOfProductIdentifier:productId]) {
                return YES;
            }
        }
    }

    // Nothing purchased
    return NO;

}

- (void)purchaseProduct:(NSString *)productId withBlock:(PFBooleanResultBlock)block {
    [self validateProductIdentifiers:@[productId] withBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Connect to AppStore" message:@"Please try again, perhaps a little later" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            [UsageAnalytics trackError:error forOperationNamed:@"lookupAppStoreProduct"];
            block(NO, error);
        } else {
            SKProduct *product = objects.firstObject;
            if (product) {
                _productCache[productId] = product;
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [numberFormatter setLocale:product.priceLocale];
                NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
                NSString *title = [NSString stringWithFormat:@"Purchase %@ now?", product.localizedTitle];
                NSString *msg = [NSString stringWithFormat:@"%@ costs %@.\n\n%@", product.localizedTitle,
                                                           formattedPrice, product.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Not Now" otherButtonTitles:@"Yes", nil]
                        showWithButtonBlock:^(NSInteger buttonIndex) {
                            if (buttonIndex == 1) {
                                [UsageAnalytics trackPurchaseDecision:YES forProductId:productId];
                                SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
                                payment.applicationUsername = [ParentUser currentUser].objectId;
                                payment.quantity = 1;
                                NSAssert(_paymentRequestCallbacks[payment.productIdentifier] == nil, @"Expected only a single payment per product to process at a time.");
                                _paymentRequestCallbacks[payment.productIdentifier] = block;
                                [[SKPaymentQueue defaultQueue] addPayment:payment];
                            } else {
                                [UsageAnalytics trackPurchaseDecision:NO forProductId:productId];
                                block(NO, nil);
                            }
                        }];

            } else {
                // No purchase data, can't offer product.
                NSString *msg = [NSString stringWithFormat:@"I'm sorry we can't offer the product '%@' right now. Please contact support with this message.", productId];
                NSError *error2 = [NSError errorWithDomain:@"com.dataparenting.DataParenting" code:100 userInfo:
                        @{NSLocalizedDescriptionKey : @"Product id not found in AppStore", @"productId" : productId}];
                [UsageAnalytics trackError:error2 forOperationNamed:@"lookupProduct"];
                [[[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
        }
    }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        [UsageAnalytics trackPurchaseTransactionState:transaction];
        PFBooleanResultBlock block = _paymentRequestCallbacks[transaction.payment.productIdentifier];
        switch (transaction.transactionState) {
            // Call the appropriate custom method.
            case SKPaymentTransactionStateRestored:
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction withBlock:block];
                [_paymentRequestCallbacks removeObjectForKey:transaction.payment.productIdentifier];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction withBlock:block];
                [_paymentRequestCallbacks removeObjectForKey:transaction.payment.productIdentifier];
                break;
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [self recordTransaction:transaction];
    _appReceipt = nil; // Clear out cached receipt.

    SKProduct *product = _productCache[transaction.payment.productIdentifier];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *currencyCode = [numberFormatter currencyCode];
    [UsageAnalytics trackPurchaseCompleted:transaction.payment.productIdentifier atPrice:product.price andCurrency:currencyCode];
    if (block) block(YES, nil);
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [UsageAnalytics trackError:transaction.error forOperationNamed:@"processPaymentTransaction"];
    [[[UIAlertView alloc] initWithTitle:@"Could not complete purchase" message:transaction.error.localizedDescription
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    [self recordTransaction:transaction];
    if (block) block(NO, transaction.error);
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    if ([ParentUser currentUser]) {
        PurchaseTransaction *purchaseTransaction = [PurchaseTransaction object];
        purchaseTransaction.user = [ParentUser currentUser];
        purchaseTransaction.txId = transaction.transactionIdentifier;
        purchaseTransaction.originalId = transaction.originalTransaction.transactionIdentifier;
        purchaseTransaction.productId = transaction.payment.productIdentifier;

        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                purchaseTransaction.type = @"new_purchase";
                break;
            case SKPaymentTransactionStateFailed:
                purchaseTransaction.type = @"failed_purchase";
                break;
            case SKPaymentTransactionStateRestored:
                purchaseTransaction.type = @"restored_purchase";
                break;
            default:
                purchaseTransaction.type = nil;
        }

        [purchaseTransaction saveEventually:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }];
    }
}


- (void)validateProductIdentifiers:(NSArray *)productIdentifiers withBlock:(PFArrayResultBlock)block {
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    objc_setAssociatedObject(productsRequest, "block", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    productsRequest.delegate = self;
    [productsRequest start];
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        NSLog(@"Unexpected invalid product id : %@", invalidIdentifier);
    }

    PFArrayResultBlock block = objc_getAssociatedObject(request, "block");
    block(response.products, nil);
}


@end