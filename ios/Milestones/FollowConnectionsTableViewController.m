//
//  InvitationsTableViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionsTableViewController.h"
#import "NSDate+HumanizedTime.h"

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
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
}

- (FollowConnection *)connection {
    return _connection;
}

- (void)setConnection:(FollowConnection *)connection {
    _connection = connection;
    // TODO: Set icon
    self.displayNameLabel.text = connection.otherPartyDisplayName;
    if (connection.inviteAcceptedOn) {
        // Connection made!
        self.acceptButton.hidden = YES;
        self.destroyButton.hidden = NO;
        self.statusLabel.text = [NSString stringWithFormat:@"For %@", [connection.inviteAcceptedOn stringWithHumanizedTimeDifference:NO]];
    } else {
        // Pending
        self.acceptButton.hidden = NO;
        self.destroyButton.hidden = NO;
        if (connection.isInviter) {
            self.statusLabel.text = [NSString stringWithFormat:@"Pending for %@", [connection.inviteSentOn stringWithHumanizedTimeDifference:NO]];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Recieved %@", [connection.inviteSentOn stringWithHumanizedTimeDifference]];
        }
    }
}

@end

@implementation FollowConnectionsTableViewController {
    NSArray *_allConnections;
    BOOL _hasMore;
    BOOL _hadError;
    BOOL _isMorganTouch;
}

- (IBAction)didClickDestroyButton:(UIButton *)sender {
}

- (IBAction)didClickAcceptButton:(UIButton *)sender {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    _hasMore = YES;
    [self loadObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
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
//                          cachePolicy:_objects.count == 0 ? kPFCachePolicyCacheThenNetwork : kPFCachePolicyNetworkOnly
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_isMorganTouch) {
        //_isMorganTouch = YES; // Not needed until/unless we open a detail page
        if (![self hasAnyConnections]) {
            _hadError = NO; // Make sure loading icon shows again
            [self.tableView reloadData];
            [self loadObjects];
        } else {
            // Nothing for now.
        }
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

//- (void)hideNotification:(BabyAssignedTip *)notificaiton withIndexPath:(NSIndexPath *)path {
//    
//    if (ParentUser.currentUser.showHiddenTips) {
//        [[[UIAlertView alloc] initWithTitle:@"Can't do that" message:@"While showing hidden tips you can not hide one. Turn off 'Show HiddenTips' in settings if you want to hide this tip." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    
//    [notificaiton saveEventually];
//    
//    [self.tableView beginUpdates];
//    [_objects removeObjectAtIndex:(NSUInteger) path.row];
//    [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationRight];
//    [self.tableView endUpdates];
//    _isEmpty = _objects.count == 0;
//    if (_isEmpty) [self.tableView reloadData];
//}


#pragma mark - SWTableViewDelegate

//- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {
//    NSIndexPath *path = [self.tableView indexPathForCell:cell];
//    BabyAssignedTip *a = [self tipForIndexPath:path];
//    if (buttonIndex == 0) {
//        [self hideNotification:a withIndexPath:path];
//    }
//}

//- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
//    if (state != kCellStateCenter) {
//        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
//    return YES;
//}


//// Work around a bug where the accessory view is on top of the slide cell.
//- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
//    if (state == kCellStateCenter) {
//        // Back to normal. Must use delay to not interfere with scroll animation.
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//            NSIndexPath *path = [self.tableView indexPathForCell:cell];
//            BabyAssignedTip *tipAssignment = [self tipForIndexPath:path];
//            cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
//        });
//    }
//}


//- (BabyAssignedTip *)tipForIndexPath:(NSIndexPath *)indexPath {
//    NSAssert(indexPath.section == 0, @"Unexpected section %ld", (long) indexPath.section);
//    return _objects[(NSUInteger) indexPath.row];
//}

- (BOOL)isLoadingRow:(NSIndexPath *)indexPath {
    return ![self hasAnyConnections];
}

@end
