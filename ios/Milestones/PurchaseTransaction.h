//
// Created by Nathan  Pahucki on 9/12/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PurchaseTransaction : PFObject <PFSubclassing>

@property ParentUser *user;
@property NSString *txId;
@property NSString *type;
@property NSString *originalId;
@property NSString *productId;
@property NSDate *date;
@property NSString *details;
@end