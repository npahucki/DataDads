//
//  InvitationsTableViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionsTableViewController.h"
#import "NSDate+HumanizedTime.h"
#import "UIImageView+URLLoading.h"
#import "NSDate+Utils.h"
#import "InviteContactsAddressBookDataSource.h"


@interface FollowConnectionsTableViewController ()

@end

@implementation FollowConnectionTableViewCell {
    FollowConnection *_connection;
}

- (void)awakeFromNib {
    [super awakeFromNib];
//    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
//    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Remove"];
//    self.rightUtilityButtons = rightUtilityButtons;
    self.displayNameLabel.textColor = [UIColor blackColor];
    self.displayNameLabel.font = [UIFont fontForAppWithType:Book andSize:15];
    self.statusLabel.textColor = [UIColor appGreyTextColor];
    self.statusLabel.font = [UIFont fontForAppWithType:Light andSize:13];


    CALayer *innerShadowLayer = [CALayer layer];
    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
    innerShadowLayer.frame = CGRectInset(self.pictureView.bounds, 2.5, 2.5);
    [self.pictureView.layer addSublayer:innerShadowLayer];
    self.pictureView.layer.borderWidth = 3;
    self.pictureView.layer.borderColor = [UIColor appNormalColor].CGColor;
    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
    self.pictureView.clipsToBounds = YES;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
}

- (FollowConnection *)connection {
    return _connection;
}

- (void)setShowAcceptButton:(BOOL)show {
    if (show) {
        self.acceptButtonWidth.constant = 44.0;
    } else {
        self.acceptButtonWidth.constant = 0;
    }
}

- (void)setConnection:(FollowConnection *)connection andDefaultAvatar:(UIImage *)defaultAvatar {
    _connection = connection;
    self.pictureView.image = defaultAvatar ? defaultAvatar : [UIImage imageNamed:@"avatarButtonDefault"];
    self.showAcceptButton = YES;
    if (connection.inviteAcceptedOn) {
        // Connection made!
        self.showAcceptButton = NO;
        if (connection.otherPartyAvatar.length) {
            [self.pictureView loadImageFromUrlString:connection.otherPartyAvatar];
        }

        if(connection.otherPartyAuxDisplayName) {
            self.displayNameLabel.text =  connection.otherPartyAuxDisplayName;
            self.statusLabel.text = [NSString stringWithFormat:@"Child of %@", connection.otherPartyDisplayName];
        } else {
            // One way follow - i.e. email grandma feature.
            self.displayNameLabel.text = connection.otherPartyDisplayName;
            self.statusLabel.text = [NSString stringWithFormat:@"Following %@", Baby.currentBaby.name];
        }
    } else {
        // Pending
        self.displayNameLabel.text = connection.otherPartyDisplayName;
        if (connection.isInviter) {
            self.statusLabel.text = [NSString stringWithFormat:@"Pending for %@", [connection.inviteSentOn stringWithHumanizedTimeDifference:NO]];
            // If the invite has been pending more than 5 days show resend button.
            if ([connection.inviteSentOn daysDifferenceFromNow] < -5) {
                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon"] forState:UIControlStateNormal];
                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon_ready"] forState:UIControlStateHighlighted];
            } else {
                self.showAcceptButton = NO;
            }
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Received %@", [connection.inviteSentOn stringWithHumanizedTimeDifference]];
            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon"] forState:UIControlStateNormal];
            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon_ready"] forState:UIControlStateHighlighted];
        }
    }
}

@end

@implementation FollowConnectionsTableViewController {
}

- (IBAction)didClickDestroyButton:(UIButton *)sender {
    FollowConnectionTableViewCell *cell = [self findTableViewCell:sender];
    if (cell.connection.inviteAcceptedOn) {
        [[[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                    message:[NSString stringWithFormat:@"Delete this connection and stop following %@?", cell.connection.otherPartyDisplayName]
                                   delegate:nil
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil]
                showWithButtonBlock:^(NSInteger buttonIndex) {
                    if (buttonIndex == 1) {
                        [self deleteConnection:cell];
                    }
                }];
    } else {
        // Just delete it, don't ask.
        [self deleteConnection:cell];
    }
}

- (IBAction)didClickAcceptButton:(UIButton *)sender {
    FollowConnectionTableViewCell *cell = [self findTableViewCell:sender];
    if (cell.connection.isInviter && !cell.connection.inviteAcceptedOn) {
        // Resend invite
        [self resendInvitation:cell];
    } else {
        [self acceptInvitation:cell];
    }
}

- (FollowConnectionTableViewCell *)findTableViewCell:(UIView *)view {
    if (view.superview == nil || [view.superview isKindOfClass:[FollowConnectionTableViewCell class]])
        return (FollowConnectionTableViewCell *) view.superview;
    else
        return [self findTableViewCell:view.superview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = YES;
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor appNormalColor];
    [self.refreshControl addTarget:self action:@selector(loadObjects) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followConnectionsDataSourceWillLoad) name:kDDNotificationFollowConnectionsDataSourceWillLoadObjects object:self.followConnectionsDataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followConnectionsDataSourceDidLoad) name:kDDNotificationFollowConnectionsDataSourceDidLoadObjects object:self.followConnectionsDataSource];
    [self loadObjects];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)networkReachabilityChanged:(NSNotification *)notification {
    if ([Reachability isParseCurrentlyReachable]) {
        [self loadObjects];
    }
}

- (void)loadObjects {
    [self.followConnectionsDataSource loadObjects];
}

- (void)followConnectionsDataSourceWillLoad {
    [self.tableView reloadData];
}

- (void)followConnectionsDataSourceDidLoad {
    // Make sure we don't show contacts that already have conenctions
    NSArray *all = [[NSArray alloc] init];
    [all arrayByAddingObjectsFromArray:[self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Connected]];
    [all arrayByAddingObjectsFromArray:[self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_WaitingToAccept]];
    [all arrayByAddingObjectsFromArray:[self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Pending]];
    for (FollowConnection *connection in all) {
        [self.contactsDataSource addExcludeContactWithEmail:connection.otherPartyEmail];
    }

    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    self.tableView.allowsSelection = !self.followConnectionsDataSource.hasAnyConnections;
}

#pragma mark UITableViewDelegate

// For now, don't load more!
//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (_hasMore && indexPath.row >= _objects.count) {
//        if ([self isLoadingRow:indexPath]) {
//            [self loadObjectsSkip:_objects.count withLimit:MAX_LOAD_COUNT];
//        }
//    }
//}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.followConnectionsDataSource connectionsInSection:(FollowConnectionDataSourceSection) section].count > 0 ? 44 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.followConnectionsDataSource.hasAnyConnections) {
        [self loadObjects];
    } else {
        // Nothing for now.
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.followConnectionsDataSource.hasAnyConnections ?
            [self.followConnectionsDataSource connectionsInSection:(FollowConnectionDataSourceSection) section].count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.followConnectionsDataSource.hasAnyConnections ? 3 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.followConnectionsDataSource.hasAnyConnections) {
        switch ((FollowConnectionDataSourceSection) section) {
            case FollowConnectionDataSourceSection_Connected:
                return @"Monitoring";
            case FollowConnectionDataSourceSection_Pending:
                return @"Pending Invitations";
            case FollowConnectionDataSourceSection_WaitingToAccept:
                return @"Waiting to Accept";
            default:
                return @"???";
        }
    } else {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.followConnectionsDataSource.hasAnyConnections) {
        FollowConnectionTableViewCell *cell = (FollowConnectionTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"connectionCell" forIndexPath:indexPath];
        NSArray *connectionsInSection = [self.followConnectionsDataSource connectionsInSection:(FollowConnectionDataSourceSection) indexPath.section];
        FollowConnection *connection = (FollowConnection *) connectionsInSection[(NSUInteger) indexPath.row];
        UIImage *defaultAvatar = [self.contactsDataSource findContactForEmailAddress:connection.otherPartyEmail].image;
        [cell setConnection:connection andDefaultAvatar:defaultAvatar];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor appGreyTextColor];
        cell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
        if (self.followConnectionsDataSource.hadError) {
            cell.textLabel.text = @"Couldn't load connections. Click to try again";
            cell.imageView.image = [UIImage imageNamed:@"error-9"];
        } else {
            cell.textLabel.text = @"Loading...";
            cell.imageView.image = nil; // TODO: remove : Work around for Bug (see 18595125)  on ios 8
            cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
        }
        return cell;
    }
}

#pragma mark - private methods

- (void)deleteConnection:(FollowConnectionTableViewCell *)connectionCell {
    [connectionCell.connection deleteInBackgroundWithBlock:nil];
    [self.contactsDataSource removeExcludeContactWithEmail:connectionCell.connection.otherPartyEmail];
    // Animate delete
    [self removeTableRow:connectionCell];
}

- (void)resendInvitation:(FollowConnectionTableViewCell *)connectionCell {
    // Next time table gets rendered, since the date is changed, the acceptButton won't be shown.
    [connectionCell.connection resendInvitationInBackgroundWithBlock:nil];
    [connectionCell setShowAcceptButton:NO];
    [[[UIAlertView alloc] initWithTitle:@"Success!" message:@"Invitation has been resent!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)acceptInvitation:(FollowConnectionTableViewCell *)connectionCell {
    [self removeTableRow:connectionCell]; // for immediate feedback
    [connectionCell.connection acceptInvitationInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // to show the newly moved rows.
        [self.followConnectionsDataSource loadObjects];
    }];
}

- (void)removeTableRow:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    // To avoid a crash, we can't animate deleting the last item
    if (self.followConnectionsDataSource.countOfTotalConnections <= 1) {
        [self.followConnectionsDataSource removeConnectionAtIndex:indexPath.row inSection:(FollowConnectionDataSourceSection) indexPath.section];
        [self.tableView reloadData];
    } else {
        [self.tableView beginUpdates];
        [self.followConnectionsDataSource removeConnectionAtIndex:indexPath.row inSection:(FollowConnectionDataSourceSection) indexPath.section];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    }
}




@end
