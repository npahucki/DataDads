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

@implementation NoteMilestoneSharingTableViewController {
    NSMutableSet *_additionalContacts;
    NSMutableSet *_excludedContacts;
    NSMutableArray *_contactList;
}

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
    _contactList = [[NSMutableArray alloc] init];
    for (FollowConnection *fc in [self.followConnectionsDataSource connectionsInSection:FollowConnectionDataSourceSection_Connected]) {
        InviteContact *ic = [[InviteContact alloc] init];
        ic.fullName = fc.otherPartyDisplayName;
        ic.emailAddress = fc.otherPartyEmail;
        [_contactList addObject:ic];
    }
    [_contactList addObjectsFromArray:[_additionalContacts allObjects]];
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    InviteContact *contact = (InviteContact *) _contactList[(NSUInteger) indexPath.row];
    if ([self isConnectionExcluded:contact]) {
        [_excludedContacts removeObject:contact];
    } else {
        // Unselect it, by excluding it.
        if (!_excludedContacts) _excludedContacts = [[NSMutableSet alloc] init];
        [_excludedContacts addObject:contact];
    }
    [self.tableView reloadData];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfContacts];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    InviteContact *contact = (InviteContact *) _contactList[(NSUInteger) indexPath.row];
    BOOL isSelected = ![self isConnectionExcluded:contact];
    cell = [tableView dequeueReusableCellWithIdentifier:@"followerCell"];
    cell.imageView.image = [self.contactsDataSource findContactForEmailAddress:contact.emailAddress].image ?: [UIImage imageNamed:@"avatarButtonDefault"];
    cell.textLabel.text = contact.fullName ?: contact.emailAddress;
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:isSelected ? @"tagCheckbox_checked" : @"tagCheckbox"]];
    return cell;
}


- (BOOL)isConnectionExcluded:(InviteContact *)connection {
    return [_excludedContacts containsObject:connection];
}

- (BOOL)hasContacts {
    return [self numberOfContacts] > 0;
}

- (NSInteger)numberOfContacts {
    return _contactList.count;
}

- (void)addFollowConnectionContact:(InviteContact *)contact {
    if (!_additionalContacts) _additionalContacts = [[NSMutableSet alloc] init];
    if (!_contactList) _contactList = [[NSMutableArray alloc] init];
    [_additionalContacts addObject:contact];
    [_contactList addObject:contact];
    [self.tableView reloadData];
}

- (NSArray *)additionalFollowerEmails {
    NSMutableArray *emails;

    if (_additionalContacts.count) {
        emails = [[NSMutableArray alloc] init];
        for (InviteContact *contact in _additionalContacts) {
            if (contact.fullName) {
                [emails addObject:[NSString stringWithFormat:@"%@ <%@>", contact.fullName, contact.emailAddress]];
            } else {
                [emails addObject:contact.emailAddress];
            }
        }
    }
    return emails;
}

- (NSArray *)excludedFollowerEmails {
    NSMutableArray *emails;
    if (_excludedContacts.count) {
        emails = [[NSMutableArray alloc] init];
        for (InviteContact *contact in _excludedContacts) {
            [emails addObject:contact.emailAddress];
        }
    }
    return emails;
}


@end