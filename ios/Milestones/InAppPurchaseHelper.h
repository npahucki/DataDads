//
// Created by Nathan  Pahucki on 9/11/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, DDProduct) {
    DDProductNone = 0,
    DDProductAdRemoval,
    DDProductVideoSupport
};

typedef NS_ENUM(NSInteger, DDProductSalesType) {
    DDProductSalesTypeOneTime = 0,
    DDProductSalesTypeSubscription
};

@interface InAppPurchaseHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (InAppPurchaseHelper *)instance;

- (void)checkAdFreeProductPurchased:(PFBooleanResultBlock)block;

- (void)checkProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block;

- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block;
@end