//
//  NoteMilestoneSharingTableViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FollowConnectionsDataSource;
@class InviteContactsAddressBookDataSource;
@class InviteContact;

@interface NoteMilestoneSharingTableViewController : UITableViewController

@property(nonatomic, strong) FollowConnectionsDataSource *followConnectionsDataSource;
@property(nonatomic, strong) InviteContactsAddressBookDataSource *contactsDataSource;
@property(readonly) BOOL hasContacts;

@property(nonatomic, readonly) NSArray *excludedFollowerEmails;
@property(nonatomic, readonly) NSArray *additionalFollowerEmails;

- (void)loadObjects;

- (void)addFollowConnectionContact:(InviteContact *)contact;
@end
