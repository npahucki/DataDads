//
// Created by Nathan  Pahucki on 9/11/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <objc/runtime.h>
#import "InAppPurchaseHelper.h"
#import "RMAppReceipt.h"
#import "RMStore.h"
#import "InAppPurchaseAlertView.h"
#import "NSError+AsDictionary.h"
#import "NSMutableDictionary+JSON.h"

static NSDictionary *productInfoForProduct(DDProduct product) {
    static NSArray *productCodes;
    if (!productCodes) {
        productCodes = @[
                @{@"id" : @"none"},
                @{@"id" : @"com.dataparenting.AdRemoval_1", @"type" : @(DDProductSalesTypeOneTime)},
                @{@"id" : @"com.dataparenting.VideoUpgrade_1", @"type" : @(DDProductSalesTypeSubscription)}];
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
#if DEBUG
    block(NO, nil); // Always show the ads in debug mode.
#else
   [self checkProductsPurchased:@[@(DDProductAdRemoval), @(DDProductVideoSupport)] withBlock:block];
    #endif
}

- (void)checkProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block {
    BOOL alreadyPurchased = [self verifyAppReceipt] && [self checkProductsPurchased:@[@(product)]];
    block(alreadyPurchased, nil); // Already purchased
}


- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block {
    if ([self verifyAppReceipt]) {
        if ([self checkProductsPurchased:@[@(product)]]) {
            block(YES, nil); // Already purchased
        } else {
            if ([SKPaymentQueue canMakePayments]) {
                [self purchaseProduct:product withBlock:block];
            } else {
                [UsageAnalytics trackAccountThatCantPurchase];
                [[[UIAlertView alloc] initWithTitle:@"Can Not Make Purchases" message:@"Your account is currently not allowed to make purchases." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                block(NO, nil);
            }
        }
    } else {
        // No receipt, need to purchase or restore
        [self purchaseProduct:product withBlock:block];
    }
}


- (void)ensureProductRestored:(DDProduct)product allowRefresh:(BOOL)refresh withBlock:(PFBooleanResultBlock)block {
    if ([self verifyAppReceipt] && [self checkProductsPurchased:@[@(product)]]) {
        block(YES, nil); // Already purchased
    } else if (refresh) {
        [[RMStore defaultStore] refreshReceiptOnSuccess:^{
            [self ensureProductRestored:product allowRefresh:NO withBlock:block];
        } failure:^(NSError *error2) {
            if ([error2.domain isEqualToString:@"SSErrorDomain"] && error2.code == 16) {
                // NOTE: This is a very odd error code, and has only been found by empirical testing
                // that this error code is issued if the user cancels the login.
                error2 = nil; // Clear it so it does not get sent along as a real error.
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Could Not Connect to AppStore" message:@"Unable to verify your purchases at this moment. Please try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                [UsageAnalytics trackError:error2 forOperationNamed:@"RMStore.refreshReceipt"];
            }
            block(NO, error2);
        }];
    } else {
        // No valid receipt or subscription is out of date.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Restore Purchases"
                                                        message:@"Either you have not purchased the product before, or your subscription is expired."
                                                       delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];

        [alert showWithButtonBlock:^(NSInteger buttonIndex) {
            [self ensureProductPurchased:product withBlock:block];
        }];
    }
}


- (BOOL)verifyAppReceipt {
#if DISABLEIAP
    return YES;
#else
    if (!_appReceipt) _appReceipt = [RMAppReceipt bundleReceipt];
    return [self verifyAppReceipt:_appReceipt];
#endif
}

- (BOOL)verifyAppReceipt:(RMAppReceipt *)receipt {
    if (!receipt) return NO;
    if (![receipt.bundleIdentifier isEqualToString:@"com.dataparenting.DataParenting"]) return NO;
    return [receipt.appVersion isEqualToString:[[NSBundle mainBundle] infoDictionary][(NSString *) kCFBundleVersionKey]] && [receipt verifyReceiptHash];
}

// If any of the products is purchased, then the block is called with YES.
// Allowing receipt refresh may prompt the user for his iTunes password.
// Thus, if you just want a 'soft' check for non critical things (like ads), don't allow refresh
- (void)checkProductsPurchased:(NSArray *)products withBlock:(PFBooleanResultBlock)block {
    if ([self verifyAppReceipt]) {
        BOOL purchased = [self checkProductsPurchased:products];
        block(purchased, nil);
    } else {
        block(NO, nil);
    }
}

// Call this method only after app receipt has been verified!
// Accepts an array of product numbers, returns true if any of the products is valid.
- (BOOL)checkProductsPurchased:(NSArray *)products {
//#if DISABLEIAP
//    return YES;
//#endif

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

- (void)purchaseProduct:(DDProduct)ddProduct withBlock:(PFBooleanResultBlock)block {
    // NOTE: In the iTunes Connect, if something happens to a product, you can not recreate it using the same id
    // thus you're screwed if the app is out in production..you'd have to deploy a new version of the app, thus
    // we build in some contingency here, so you can create the same product with an alternate name and not have to
    // deploy the app again.
    NSString *productId = productInfoForProduct(ddProduct)[@"id"];
    NSArray *productIds = @[
            productId,
            [productId stringByAppendingString:@".1"],
            [productId stringByAppendingString:@".2"],
            [productId stringByAppendingString:@".3"]
    ];

    // Show view with loading indicator
    InAppPurchaseAlertView *alert = [[InAppPurchaseAlertView alloc] init];
    PFBooleanResultBlock wrapperBlock = ^(BOOL succeeded, NSError *error) {
        [alert close];
        block(succeeded, error);
    };

    //Show the dialog first, so the user has some indication of what is going on
    [alert showWithBlock:^(InAppPurchaseChoice choice) {
        if (choice == InAppPurchaseChoicePurchase) {
            [UsageAnalytics trackPurchaseDecision:YES forProductId:productId];
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:alert.product];
            payment.applicationUsername = [ParentUser currentUser].objectId;
            payment.quantity = 1;
            NSAssert(_paymentRequestCallbacks[payment.productIdentifier] == nil, @"Expected only a single payment per product to process at a time.");
            _paymentRequestCallbacks[payment.productIdentifier] = wrapperBlock;
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        } else if (choice == InAppPurchaseChoiceRestore) {
            [self ensureProductRestored:ddProduct allowRefresh:YES withBlock:wrapperBlock];
        } else {
            [UsageAnalytics trackPurchaseDecision:NO forProductId:productId];
            wrapperBlock(NO, nil);
        }
    }];

    // Look up and present the product to the user
    [self validateProductIdentifiers:productIds withBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Connect to AppStore" message:@"Try your again in a little while since this could have been caused by a network hiccup." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            [UsageAnalytics trackError:error forOperationNamed:@"lookupAppStoreProduct"];
            block(NO, error);
        } else {
            SKProduct *product = objects.firstObject;
            if (product) {
                _productCache[productId] = product;
                alert.product = product; // This will activate the dialog.
            } else {
                // No purchase data, can't offer product.
                NSString *msg = [NSString stringWithFormat:@"I'm sorry we can't offer the product '%@' right now. Please contact support with this message.", productId];
                NSError *error2 = [NSError errorWithDomain:@"com.dataparenting.DataParenting" code:100 userInfo:
                        @{NSLocalizedDescriptionKey : @"Product id not found in AppStore", @"productId" : productId}];
                [UsageAnalytics trackError:error2 forOperationNamed:@"lookupProduct"];
                [[[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                wrapperBlock(NO, error);
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
                NSLog(@"Transaction for product %@: state:%ld ", transaction.payment.productIdentifier, (unsigned long) transaction.transactionState);
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
    if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
        if (product.price)
            [UsageAnalytics trackPurchaseCompleted:transaction.payment.productIdentifier atPrice:product.price andCurrency:currencyCode];
        else
            NSLog(@"Got transaction %@ with no price!", transaction.transactionIdentifier);
    } else {
        [UsageAnalytics trackPurchaseRestored:transaction.payment.productIdentifier];
    }
    if (block) block(YES, nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationProductPurchased object:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction withBlock:(PFBooleanResultBlock)block {
    [UsageAnalytics trackError:transaction.error forOperationNamed:@"processPaymentTransaction"];
    if (transaction.error.code != SKErrorPaymentCancelled && transaction.error.code != SKErrorPaymentNotAllowed) {
        [[[UIAlertView alloc] initWithTitle:@"Could Not Complete Purchase/Restore" message:[transaction.error.localizedDescription stringByAppendingString:@". Try your purchase again in a little while since this could have been caused by a network hiccup."]
                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
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
        purchaseTransaction.date = transaction.transactionDate;
        NSMutableDictionary *errorDetails = nil;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                purchaseTransaction.type = @"new_purchase";
                break;
            case SKPaymentTransactionStateFailed:
                errorDetails = [transaction.error asDictionary];
                switch (transaction.error.code) {
                    case SKErrorClientInvalid:
                        errorDetails[@"skReasonCode"] = @"SKErrorClientInvalid";
                        break;
                    case SKErrorPaymentCancelled:
                        errorDetails[@"skReasonCode"] = @"SKErrorPaymentCancelled";
                        break;
                    case SKErrorPaymentInvalid:
                        errorDetails[@"skReasonCode"] = @"SKErrorPaymentInvalid";
                        break;
                    case SKErrorPaymentNotAllowed:
                        errorDetails[@"skReasonCode"] = @"SKErrorPaymentNotAllowed";
                        break;
                    case SKErrorStoreProductNotAvailable:
                        errorDetails[@"skReasonCode"] = @"SKErrorStoreProductNotAvailable";
                        break;
                    case SKErrorUnknown:
                    default:
                        errorDetails[@"skReasonCode"] = @"SKErrorUnknown";
                        break;
                }

                purchaseTransaction.details = [errorDetails toJsonString];
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
                NSLog(@"Recorded Transaction for Product: %@", transaction.payment.productIdentifier);
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
        NSLog(@"Invalid products id : %@", invalidIdentifier);
    }

    PFArrayResultBlock block = objc_getAssociatedObject(request, "block");
    block(response.products, nil);
}


@end