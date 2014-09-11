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


@interface InAppPurchaseHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (NSArray *)productCodes;

+ (InAppPurchaseHelper *)instance;


- (void)ensureProductPurchased:(DDProduct)product withBlock:(PFBooleanResultBlock)block;

@end