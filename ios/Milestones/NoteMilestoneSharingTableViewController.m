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

@implementation NoteMilestoneSharingTableViewControllerCell {
    BOOL _isChecked;
    InviteContact *_contact;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contactPhoto.clipsToBounds = YES;
    self.contactNameLabel.textColor = [UIColor blackColor];
    self.contactNameLabel.font = [UIFont fontForAppWithType:Book andSize:18];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CALayer *innerShadowLayer = [CALayer layer];
    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
    innerShadowLayer.frame = CGRectInset(self.contactPhoto.bounds, 2.5, 2.5);
    [self.contactPhoto.layer addSublayer:innerShadowLayer];
    self.contactPhoto.layer.borderWidth = 3;
    self.contactPhoto.layer.borderColor = [UIColor appNormalColor].CGColor;
    self.contactPhoto.layer.cornerRadius = self.contactPhoto.bounds.size.width / 2;
}

- (BOOL)checked {
    return _isChecked;
}

- (void)setChecked:(BOOL)checked {
    _isChecked = checked;
    self.checkMarkImageView.image = [UIImage imageNamed:checked ? @"tagCheckbox_checked" : @"tagCheckbox"];
}

- (InviteContact *)contact {
    return _contact;
}

- (void)setContact:(InviteContact *)contact withPhoto:(UIImage *)photo {
    _contact = contact;
    self.contactPhoto.image = photo ?: [UIImage imageNamed:@"avatarButtonDefault"];
    self.contactNameLabel.text = contact.fullName ?: contact.emailAddress;
}


@end

@implementation NoteMilestoneSharingTableViewController {
    NSMutableSet *_additionalContacts;
    NSMutableSet *_excludedContacts;
    NSMutableArray *_contactList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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
    InviteContact *contact = (InviteContact *) _contactList[(NSUInteger) indexPath.row];
    NoteMilestoneSharingTableViewControllerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"followerCell"];
    [cell setContact:contact withPhoto:[self.contactsDataSource findContactForEmailAddress:contact.emailAddress].image];
    cell.checked = ![self isConnectionExcluded:contact];
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