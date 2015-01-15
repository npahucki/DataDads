//
//  InvitationsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <MBContactPicker/MBContactPicker.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MainFollowConnectionsViewController.h"
#import "InviteContactsAddressBookDataSource.h"
#import "FollowConnectionsTableViewController.h"
#import "NSString+EmailAddress.h"


@interface MainFollowConnectionsViewController ()
@property(readonly) InviteContactsAddressBookDataSource *addressBookDataSource;
@end

@implementation MainFollowConnectionsViewController {
    FollowConnectionsTableViewController *_tableController;
    InviteContactsAddressBookDataSource *_addressBookDataSource;
    FollowConnectionsDataSource *_dataSource;
    BOOL _inviteMode;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _dataSource = [[FollowConnectionsDataSource alloc] init];
    // Register here so we can handle these in the background, EVEN if the tab has never been selected
    // since selecting the tab the first time is what triggers viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followConnectionsDataSourceDidChange) name:kDDNotificationFollowConnectionsDataSourceDidChange object:_dataSource];
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];

    self.pickerView.layer.borderColor = [UIColor appNormalColor].CGColor;
    self.pickerView.layer.borderWidth = 1;
    self.pickerView.allowsCompletionOfSelectedContacts = NO;
    self.pickerView.prompt = @"Invite:";
    self.pickerView.maxVisibleRows = 5;
    self.pickerView.delegate = self;
    self.pickerView.datasource = self.addressBookDataSource;
    [[MBContactCollectionViewContactCell appearance] setTintColor:[UIColor appNormalColor]];
    self.inviteMode = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [_addressBookDataSource clearCache];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[FollowConnectionsTableViewController class]]) {
        _tableController = (FollowConnectionsTableViewController *) segue.destinationViewController;
        _tableController.contactsDataSource = self.addressBookDataSource;
        _tableController.followConnectionsDataSource = _dataSource;
    }
}

- (IBAction)didClickInviteButton:(id)sender {
    if (_inviteMode) {
        if (_pickerView.contactsSelected.count > 0) [self sendInvites];
        self.inviteMode = NO;
    } else {
        self.inviteMode = YES;
    }
}

- (InviteContactsAddressBookDataSource *)addressBookDataSource {
    if (!_addressBookDataSource) {
        _addressBookDataSource = [[InviteContactsAddressBookDataSource alloc] init];
        [_addressBookDataSource addExcludeContactWithEmail:[PFUser currentUser].email];
    }
    return _addressBookDataSource;
}

- (void)setInviteMode:(BOOL)inviteMode {
    _inviteMode = inviteMode;
    if (_inviteMode) {
        self.inviteButton.style = UIBarButtonItemStyleDone;
        self.inviteButton.title = @"Done";
        self.inviteButton.image = nil;
        [self.pickerView reloadData];
        [self.pickerView becomeFirstResponder];
        self.pickerHeightConstraint.constant = self.pickerView.currentContentHeight;
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.pickerView resignFirstResponder];
        self.pickerHeightConstraint.constant = 0;
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
        self.inviteButton.style = UIBarButtonItemStylePlain;
        self.inviteButton.title = nil;
        self.inviteButton.image = [UIImage imageNamed:@"createButton"];
    }
}

- (void)followConnectionsDataSourceDidChange {
    [self updateBadgeFromCurrent];
}

- (void)gotPushNotification:(NSNotification *)notice {
    // First check if it is a tipsNotification, ignore if not.
    if ([kDDPushNotificationTypeFollowConnection isEqualToString:notice.userInfo[kDDPushNotificationField_CData][kDDPushNotificationField_Type]]) {
        [_dataSource loadObjects];
    }
}

- (void)updateBadgeFromCurrent {
    NSInteger waitingInvitationsCount = [_dataSource connectionsInSection:FollowConnectionDataSourceSection_WaitingToAccept].count;
    NSInteger oldBadgeNumber = self.navigationController.tabBarItem.badgeValue.integerValue;
    if (waitingInvitationsCount > oldBadgeNumber) {
        // Play sound
        AudioServicesPlaySystemSound(1003);
    }
    self.navigationController.tabBarItem.badgeValue = waitingInvitationsCount > 0 ? @(waitingInvitationsCount).stringValue : nil;
}

- (void)appEnterForeground:(NSNotification *)notice {
    [_dataSource loadObjects];
}

- (void)sendInvites {

    // We need a name from which to send the invite.
    [self makeBestAttemptToPopulateSendersFullNameWithBlock:^(NSString *string, NSError *error) {
        NSMutableArray *inviteArray = [[NSMutableArray alloc] initWithCapacity:_pickerView.contactsSelected.count];
        for (InviteContact *contact in _pickerView.contactsSelected) {
            NSAssert(contact.emailAddress, @"Unexpected nil emailAddress");
            [inviteArray addObject:@{
                    @"sendToName" : contact.fullName ? contact.fullName : [NSNull null],
                    @"sendToEmail" : contact.emailAddress
            }];
        }
        [PFCloud callFunctionInBackground:@"sendFollowInvitation"
                           withParameters:@{@"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                                   @"invites" : inviteArray}
                                    block:^(NSArray *objects, NSError *blockError) {
                                        if (blockError) {
                                            [UsageAnalytics trackError:blockError forOperationNamed:@"sendInvites"];
                                            [[[UIAlertView alloc] initWithTitle:@"Could Not Send Invites" message:@"There was an error trying to send the invites. Make sure you have an internet connection and try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                                        }

                                        // Show any invites in the window now.
                                        [_dataSource loadObjects];
                                    }];
    }];
}

- (void)makeBestAttemptToPopulateSendersFullNameWithBlock:(PFStringResultBlock)block {
    ParentUser *user = [ParentUser currentUser];
    if (!user.fullName.length) {
        // This is probably the most accurate one.
        user.fullName = [_addressBookDataSource findContactForEmailAddress:user.email].fullName;
        if (!user.fullName.length) {
            // Then Facebook (sometimes people put odd/fake names in Facebook)
            if ([PFFacebookUtils isLinkedWithUser:user]) {
                // Try to get information from Facebook
                [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    NSString *usersName = result[@"name"];
                    if (usersName.length) {
                        user.fullName = usersName;
                    } else {
                        user.fullName = [ParentUser nameFromCurrentDevice];
                    }
                    if (user.fullName.length) [user saveEventually];
                    block(user.fullName, nil);
                }];
            } else {
                user.fullName = [ParentUser nameFromCurrentDevice];
            }
        }

        // Save if assigned
        if (user.fullName.length) [user saveEventually];
    }

    block(user.fullName, nil);
}


#pragma mark - MBContactPickerDelegate


// NOTE: This method is named badly.
- (void)contactPicker:(MBContactPicker *)contactPicker didEnterCustomText:(NSString *)text {
    if (text.isValidEmailAddress) {
        InviteContact *contact = [[InviteContact alloc] init];
        contact.emailAddress = text;
        [_pickerView addToSelectedContacts:contact];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Invalid email address, please correct it"
                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

// This delegate method is called to allow the parent view to increase the size of
// the contact picker view to show the search table view
- (void)didShowFilteredContactsForContactPicker:(MBContactPicker *)contactPicker {
    if (self.pickerHeightConstraint.constant <= contactPicker.currentContentHeight) {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            CGRect pickerRectInWindow = [self.view convertRect:contactPicker.frame fromView:nil];
            CGFloat newHeight = self.view.window.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight;
            self.pickerHeightConstraint.constant = newHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is called to allow the parent view to decrease the size of
// the contact picker view to hide the search table view
- (void)didHideFilteredContactsForContactPicker:(MBContactPicker *)contactPicker {
    if (self.pickerHeightConstraint.constant > contactPicker.currentContentHeight) {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            self.pickerHeightConstraint.constant = contactPicker.currentContentHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is invoked to allow the parent to increase the size of the
// collectionview that shows which contacts have been selected. To increase or decrease
// the number of rows visible, change the maxVisibleRows property of the MBContactPicker
- (void)contactPicker:(MBContactPicker *)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight {
    self.pickerHeightConstraint.constant = newHeight;
    [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
        [self.view layoutIfNeeded];
    }];
}





@end
