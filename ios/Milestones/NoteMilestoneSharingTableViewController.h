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

@interface NoteMilestoneSharingTableViewController : UITableViewController

@property(nonatomic, strong) FollowConnectionsDataSource *followConnectionsDataSource;
@property(nonatomic, strong) InviteContactsAddressBookDataSource *contactsDataSource;
@property(readonly) BOOL hasConnections;

- (void)loadObjects;
@end
