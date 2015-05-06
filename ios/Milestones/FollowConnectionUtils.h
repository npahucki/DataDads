//
// Created by Nathan  Pahucki on 4/30/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFConstants.h>

@class InviteContactsAddressBookDataSource;


@interface FollowConnectionUtils : NSObject
+ (void)makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource withBlock:(PFStringResultBlock)block;

+ (void)makeBestAttemptToPopulateSendersFullNameWithAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource;

+ (void)ensureCurrentUserHasEmailPresentIn:(UIViewController *)viewController andRunBlock:(PFBooleanResultBlock)block;
@end