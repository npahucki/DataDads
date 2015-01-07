//
//  InvitationsTableViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SWTableViewCell.h"
#import "CirclePictureTableViewCell.h"


@interface FollowConnectionTableViewCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIButton *destroyButton;
@property(weak, nonatomic) IBOutlet UIButton *acceptButton;
@property(weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *statusLabel;
@property(weak, nonatomic) IBOutlet UIImageView *pictureView;
@property(retain, nonatomic) FollowConnection *connection;


@end


@interface FollowConnectionsTableViewController : UITableViewController <SWTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource>

- (void)loadObjects;

@end
