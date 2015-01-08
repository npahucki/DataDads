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
#import "PFCloud+Cache.h"

#define MAX_LOAD_COUNT 50

#define SECTION_WAITING_TO_ACCEPT 0
#define SECTION_CONNECTED 1
#define SECTION_SENT_PENDING 2


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

- (void)setConnection:(FollowConnection *)connection {
    _connection = connection;
    self.pictureView.image = [UIImage imageNamed:@"avatarButtonDefault"];
    self.showAcceptButton = YES;
    if (connection.inviteAcceptedOn) {
        // Connection made!
        self.showAcceptButton = NO;
        self.displayNameLabel.text = connection.otherPartyAuxDisplayName;
        self.statusLabel.text = [NSString stringWithFormat:@"Child of %@", connection.otherPartyDisplayName];
        [self.pictureView loadImageFromUrlString:connection.otherPartyAvatar];
    } else {
        // Pending
        self.displayNameLabel.text = connection.otherPartyDisplayName;
        if (connection.isInviter) {
            self.statusLabel.text = [NSString stringWithFormat:@"Pending for %@", [connection.inviteSentOn stringWithHumanizedTimeDifference:NO]];
            // If the invite has been pending more than 5 days show resend button.
            if ([connection.inviteSentOn daysDifferenceFromNow] > 5) {
                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon"] forState:UIControlStateNormal];
                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon_ready"] forState:UIControlStateHighlighted];
            } else {
                self.showAcceptButton = NO;
            }
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Recieved %@", [connection.inviteSentOn stringWithHumanizedTimeDifference]];
            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon"] forState:UIControlStateNormal];
            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon_ready"] forState:UIControlStateHighlighted];
        }
    }
}

@end

@implementation FollowConnectionsTableViewController {
    NSArray *_allConnections;
    BOOL _hasMore;
    BOOL _hadError;
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
    _hasMore = YES;
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
    [self loadObjectsWithLimit:MAX_LOAD_COUNT];
}

- (void)loadObjectsWithLimit:(NSInteger)limit {
    [PFCloud callFunctionInBackground:@"queryMyFollowConnections"
                       withParameters:@{@"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                               @"limit" : [@(limit) stringValue]}
                          cachePolicy:[self hasAnyConnections] ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork
                                block:^(NSArray *objects, NSError *error) {
                                    _hadError = error != nil;
                                    if (!_hadError) {
                                        [self resetAllConnections];
                                        // Go through and sort the follow connections into buckets
                                        for (FollowConnection *conn in objects) {
                                            if (conn.inviteAcceptedOn) {
                                                [_allConnections[SECTION_CONNECTED] addObject:conn];
                                            } else if (conn.isInviter) {
                                                [_allConnections[SECTION_SENT_PENDING] addObject:conn];
                                            } else {
                                                [_allConnections[SECTION_WAITING_TO_ACCEPT] addObject:conn];
                                            }
                                        }
                                        _hasMore = objects.count == MAX_LOAD_COUNT;
                                    }
                                    [self.tableView reloadData];
                                    [self.refreshControl endRefreshing];
                                    self.tableView.allowsSelection = ![self hasAnyConnections];
                                }];
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
    return ((NSArray *) _allConnections[(NSUInteger) section]).count > 0 ? 44 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self hasAnyConnections]) {
        _hadError = NO; // Make sure loading icon shows again
        [self.tableView reloadData];
        [self loadObjects];
    } else {
        // Nothing for now.
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self hasAnyConnections] ? ((NSArray *) _allConnections[(NSUInteger) section]).count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self hasAnyConnections] ? 3 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self hasAnyConnections]) {
        switch (section) {
            case SECTION_CONNECTED:
                return @"Following";
            case SECTION_SENT_PENDING:
                return @"Pending Invitations";
            case SECTION_WAITING_TO_ACCEPT:
                return @"Waiting to Accept";
            default:
                return @"???";
        }
    } else {
        return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasAnyConnections]) {
        FollowConnectionTableViewCell *cell = (FollowConnectionTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"connectionCell" forIndexPath:indexPath];
        [cell setConnection:(FollowConnection *) ((NSArray *) _allConnections[(NSUInteger) indexPath.section])[(NSUInteger) indexPath.row]];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor appGreyTextColor];
        cell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
        if (_hadError) {
            cell.textLabel.text = @"Couldn't load connections. Click to try again";
            cell.imageView.image = [UIImage imageNamed:@"error-9"];
        } else {
            if (!_hasMore) {
                cell.textLabel.text = @"No connections to show now. Touch here to refresh";
                cell.imageView.image = [UIImage imageNamed:@"tipsButton_active"];
            } else {
                cell.textLabel.text = @"Loading...";
                cell.imageView.image = nil; // TODO: remove : Work around for Bug (see 18595125)  on ios 8
                cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
            }
        }
        return cell;
    }
}


#pragma mark - private methods

- (void)deleteConnection:(FollowConnectionTableViewCell *)connectionCell {
    [connectionCell.connection deleteInBackgroundWithBlock:nil];
    // Animate delete
    NSIndexPath *pathToDelete = [self.tableView indexPathForCell:connectionCell];
    [self.tableView beginUpdates];
    NSMutableArray *sectionArray = (NSMutableArray *) _allConnections[(NSUInteger) pathToDelete.section];
    [sectionArray removeObjectAtIndex:(NSUInteger) pathToDelete.row];
    [self.tableView deleteRowsAtIndexPaths:@[pathToDelete] withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];

    if (![self hasAnyConnections]) {
        // TODO: Show the other view describing how to add connections!
        [self.tableView reloadData];
    }
}

- (void)resendInvitation:(FollowConnectionTableViewCell *)connectionCell {
    // Next time table gets rendered, since the date is changed, the acceptButton won't be shown.
    [connectionCell.connection resendInvitationInBackgroundWithBlock:nil];
    [connectionCell setShowAcceptButton:NO];
    [[[UIAlertView alloc] initWithTitle:@"Success!" message:@"Invitation has been resent!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)acceptInvitation:(FollowConnectionTableViewCell *)connectionCell {
    [connectionCell.connection acceptInvitationInBackgroundWithBlock:nil];
    NSIndexPath *pathToDelete = [self.tableView indexPathForCell:connectionCell];
    [self.tableView beginUpdates];
    NSMutableArray *sectionArray = (NSMutableArray *) _allConnections[(NSUInteger) pathToDelete.section];
    [sectionArray removeObjectAtIndex:(NSUInteger) pathToDelete.row];
    [self.tableView deleteRowsAtIndexPaths:@[pathToDelete] withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    [self loadObjects];
}



- (void)resetAllConnections {
    NSMutableArray *allConnections = [[NSMutableArray alloc] initWithCapacity:3];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    _allConnections = allConnections;
}

- (BOOL)hasAnyConnections {
    for (NSArray *array in _allConnections) {
        if (array.count > 0) return YES;
    }
    return NO;
}
@end
