//
//  NoteMilestoneSharingTableViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSharingTableViewController.h"
#import "FollowConnectionsDataSource.h"
#import "InviteContactsAddressBookDataSource.h"


//@implementation FollowConnectionTableViewCell {
//    FollowConnection *_connection;
//    
//}
//
//- (void)awakeFromNib {
//    [super awakeFromNib];
//    //    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
//    //    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Remove"];
//    //    self.rightUtilityButtons = rightUtilityButtons;
//    self.displayNameLabel.textColor = [UIColor blackColor];
//    self.displayNameLabel.font = [UIFont fontForAppWithType:Book andSize:15];
//    self.statusLabel.textColor = [UIColor appGreyTextColor];
//    self.statusLabel.font = [UIFont fontForAppWithType:Light andSize:13];
//    
//    
//    CALayer *innerShadowLayer = [CALayer layer];
//    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
//    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
//    innerShadowLayer.frame = CGRectInset(self.pictureView.bounds, 2.5, 2.5);
//    [self.pictureView.layer addSublayer:innerShadowLayer];
//    self.pictureView.layer.borderWidth = 3;
//    self.pictureView.layer.borderColor = [UIColor appNormalColor].CGColor;
//    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
//    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
//    self.pictureView.clipsToBounds = YES;
//    
//}
//
//- (void)layoutSubviews {
//    [super layoutSubviews];
//    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
//}
//
//- (void)setConnection:(FollowConnection *)connection andDefaultAvatar:(UIImage *)defaultAvatar {
//    _connection = connection;
//    self.pictureView.image = defaultAvatar ? defaultAvatar : [UIImage imageNamed:@"avatarButtonDefault"];
//    self.showAcceptButton = YES;
//    if (connection.inviteAcceptedOn) {
//        // Connection made!
//        self.showAcceptButton = NO;
//        if (connection.otherPartyAvatar.length) {
//            [self.pictureView loadImageFromUrlString:connection.otherPartyAvatar];
//        }
//        
//        if(connection.otherPartyAuxDisplayName) {
//            self.displayNameLabel.text =  connection.otherPartyAuxDisplayName;
//            self.statusLabel.text = [NSString stringWithFormat:@"Child of %@", connection.otherPartyDisplayName];
//        } else {
//            // One way follow - i.e. email grandma feature.
//            self.displayNameLabel.text = connection.otherPartyDisplayName;
//            self.statusLabel.text = [NSString stringWithFormat:@"Following %@", Baby.currentBaby.name];
//        }
//    } else {
//        // Pending
//        self.displayNameLabel.text = connection.otherPartyDisplayName;
//        if (connection.isInviter) {
//            self.statusLabel.text = [NSString stringWithFormat:@"Pending for %@", [connection.inviteSentOn stringWithHumanizedTimeDifference:NO]];
//            // If the invite has been pending more than 5 days show resend button.
//            if ([connection.inviteSentOn daysDifferenceFromNow] < -5) {
//                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon"] forState:UIControlStateNormal];
//                [self.acceptButton setImage:[UIImage imageNamed:@"redoIcon_ready"] forState:UIControlStateHighlighted];
//            } else {
//                self.showAcceptButton = NO;
//            }
//        } else {
//            self.statusLabel.text = [NSString stringWithFormat:@"Received %@", [connection.inviteSentOn stringWithHumanizedTimeDifference]];
//            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon"] forState:UIControlStateNormal];
//            [self.acceptButton setImage:[UIImage imageNamed:@"acceptIcon_ready"] forState:UIControlStateHighlighted];
//        }
//    }
//}
//
//@end

@implementation NoteMilestoneSharingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor appNormalColor];
    [self.refreshControl addTarget:self action:@selector(loadObjects) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
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

- (void)followConnectionsDataSourceDidLoad {
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Select/unelect
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Connected].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (self.followConnectionsDataSource.hasAnyConnections) {
        NSArray *connectionsInSection = [self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Connected];
        FollowConnection *connection = (FollowConnection *) connectionsInSection[(NSUInteger) indexPath.row];
        BOOL isSelected = [self isConnectionSelected:connection];
        cell = [tableView dequeueReusableCellWithIdentifier:@"followerCell"];
        cell.imageView.image = [self.contactsDataSource findContactForEmailAddress:connection.otherPartyEmail].image ?: [UIImage imageNamed:@"avatarButtonDefault"];
        cell.textLabel.text = connection.otherPartyDisplayName ?: connection.otherPartyEmail;
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:isSelected ? @"tagCheckbox_checked" : @"tagCheckbox"]];
    }
    return cell;
}

- (BOOL)isConnectionSelected:(FollowConnection *)connection {
    return true; // TODO:
}

- (BOOL)hasConnections {
    return [self numberOfConnections] > 0;
}

- (NSInteger)numberOfConnections {
    return [self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Connected].count;
}

@end