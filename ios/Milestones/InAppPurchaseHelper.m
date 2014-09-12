//
// Created by Nathan  Pahucki on 9/11/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <objc/runtime.h>
#import "InAppPurchaseHelper.h"
#import "RMStore.h"
#import "RMStoreAppReceiptVerificator.h"
#import "RMAppReceipt.h"
#import "NSDate+Utils.h"


@implementation InAppPurchaseHelper {
    RMStoreAppReceiptVerificator *_verificator;
    NSMutableDictionary *_paymentRequestCallbacks; // Naughty apple does not use the same SKPayment object, so we need to track blocks here.
    NSMutableDictionary *_productPurchaseCache;
}

+ (NSString *)productCodesForProduct:(DDProduct)product {
    static NSArray *productCodes;
    if (!productCodes) {
        productCodes = @[@"none", @"com.dataparenting.ad_removal", @"com.dataparenting.video_1"];
    }
    return productCodes[product];
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
        _productPurchaseCache = [[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        _verificator = [[RMStoreAppReceiptVerificator alloc] init];
        _verificator.bundleIdentifier = @"com.dataparenting.DataParenting";
        _verificator.bundleVersion = [[NSBundle mainBundle] infoDictionary][(NSString *) kCFBundleVersionKey];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block {
    NSString *productId = [InAppPurchaseHelper productCodesForProduct:product];
    if ([self isProductPurchaseInCache:productId]) {
        block(YES, nil);
    } else {
        if ([_verificator verifyAppReceipt]) {
            RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
            NSDate *today = [NSDate date];
            if ([receipt containsActiveAutoRenewableSubscriptionOfProductIdentifier:productId forDate:today]) {
                _productPurchaseCache[productId] = today;
                // Already purchased
                block(YES, nil);
            } else {
                if ([SKPaymentQueue canMakePayments]) {
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
}

- (BOOL)isProductPurchaseInCache:(NSString *)productId {
    NSDate *cachedDate = _productPurchaseCache[productId];
    return cachedDate && [cachedDate daysDifferenceFromNow] <= 1;
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
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction withBlock:block];
                [_paymentRequestCallbacks removeObjectForKey:transaction.payment.productIdentifier];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction withBlock:block];
                [_paymentRequestCallbacks removeObjectForKey:transaction.payment.productIdentifier];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction withBlock:block];
                [_paymentRequestCallbacks removeObjectForKey:transaction.payment.productIdentifier];
                break;
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [self recordTransaction:transaction];
    block(YES, nil);
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [self recordTransaction:transaction];
    block(YES, nil);
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [UsageAnalytics trackError:transaction.error forOperationNamed:@"activateVideo"];
    [[[UIAlertView alloc] initWithTitle:@"Could not complete purchase" message:transaction.error.localizedDescription
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    [self recordTransaction:transaction];
    block(NO, transaction.error);
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
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