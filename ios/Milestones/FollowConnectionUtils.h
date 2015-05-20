//
// Created by Nathan  Pahucki on 4/30/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFConstants.h>

@class InviteContactsAddressBookDataSource;
@class BFTask;


@interface FollowConnectionUtils : NSObject
+ (BFTask *)makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource;

+ (void)makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource withBlock:(PFStringResultBlock)block;

+ (void)makeBestAttemptToPopulateSendersFullNameWithAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource;

+ (BFTask *)ensureCurrentUserHasEmailPresentIn:(UIViewController *)viewController;

+ (void)ensureCurrentUserHasEmailPresentIn:(UIViewController *)viewController andRunBlock:(PFBooleanResultBlock)block;
@end