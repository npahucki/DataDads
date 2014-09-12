//
// Created by Nathan  Pahucki on 9/12/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PurchaseTransaction : PFObject <PFSubclassing>

@property(retain, nonatomic) ParentUser *user;
@property(retain, nonatomic) NSString *txId;
@property(retain, nonatomic) NSString *type;
@property(retain, nonatomic) NSString *originalId;
@property(retain, nonatomic) NSString *productId;
@property(retain, nonatomic) NSDate *date;


@end