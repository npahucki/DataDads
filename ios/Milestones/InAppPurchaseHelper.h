//
// Created by Nathan  Pahucki on 9/11/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


typedef enum _DDProduct : NSUInteger {
    DDProductNone = 0,
    DDProductAdRemoval,
    DDProductVideoSupport
} DDProduct;

typedef enum _DDProductSalesType : NSUInteger {
    DDProductSalesTypeOneTime = 0,
    DDProductSalesTypeSubscription
} DDProductSalesType;



@interface InAppPurchaseHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (InAppPurchaseHelper *)instance;

- (void)checkAdFreeProductPurchased:(PFBooleanResultBlock)block;

- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block;
@end