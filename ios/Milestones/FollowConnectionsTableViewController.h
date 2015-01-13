//
//  InvitationsTableViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SWTableViewCell.h"
#import "CirclePictureTableViewCell.h"

@class InviteContactsAddressBookDataSource;


@interface FollowConnectionTableViewCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIButton *destroyButton;
@property(weak, nonatomic) IBOutlet UIButton *acceptButton;
@property(weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *statusLabel;
@property(weak, nonatomic) IBOutlet UIImageView *pictureView;
@property(readonly, nonatomic) FollowConnection *connection;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *acceptButtonWidth;

- (void)setConnection:(FollowConnection *)connection andDefaultAvatar:(UIImage *)defaultAvatar;

@end


@interface FollowConnectionsTableViewController : UITableViewController <SWTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) InviteContactsAddressBookDataSource *contactsDataSource;

- (void)loadObjects;

@end
