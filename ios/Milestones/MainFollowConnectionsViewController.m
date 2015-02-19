//
//  InvitationsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MainFollowConnectionsViewController.h"
#import "InviteContactsAddressBookDataSource.h"
#import "FollowConnectionsTableViewController.h"
#import "NSString+EmailAddress.h"
#import "FollowConnectionsNothingToShowViewController.h"
#import "SignUpOrLoginViewController.h"


@interface MainFollowConnectionsViewController ()
@property(readonly) InviteContactsAddressBookDataSource *addressBookDataSource;
@end

@implementation MainFollowConnectionsViewController {
    FollowConnectionsTableViewController *_tableController;
    InviteContactsAddressBookDataSource *_addressBookDataSource;
    FollowConnectionsDataSource *_dataSource;
    BOOL _inviteMode;
    BOOL _showedPermissionWarning;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _dataSource = [[FollowConnectionsDataSource alloc] init];
    // Register here so we can handle these in the background, EVEN if the tab has never been selected
    // since selecting the tab the first time is what triggers viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlOpened:) name:kDDNotificationURLOpened object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followConnectionsDataSourceDidChange) name:kDDNotificationFollowConnectionsDataSourceDidChange object:_dataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut) name:kDDNotificationUserLoggedOut object:nil];
    return self;
}

- (void)userDidLogOut {
    [_dataSource loadObjects];
    [_addressBookDataSource clearCache];
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

    self.containerView.hidden = YES;
    self.pickerView.hidden = YES; // Start hidden so we don't adjust the size during the delegate method, until the user has initially pressed the button to expand.
    self.nothingToShowContainerView.hidden = YES;
    
    [self setInviteMode:NO withAnimation:NO];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Don't show the 'New' badge once the tab is activated.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"v1.3MonitorTabTouched"];

    [_addressBookDataSource clearCache];
    [self updateContainerViewState];
    [self updateBadgeFromCurrent];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[FollowConnectionsTableViewController class]]) {
        _tableController = (FollowConnectionsTableViewController *) segue.destinationViewController;
        _tableController.followConnectionsDataSource = _dataSource;
        _tableController.contactsDataSource = self.addressBookDataSource;
    } else if ([segue.destinationViewController isKindOfClass:[FollowConnectionsNothingToShowViewController class]]) {
        FollowConnectionsNothingToShowViewController *vc = (FollowConnectionsNothingToShowViewController *) segue.destinationViewController;
        vc.mainFollowController = self;
    }
}

- (void)updateContainerViewState {
    self.inviteButton.enabled = [PFUser currentUser].email != nil;
    BOOL showContainerView = [PFUser currentUser].email && (_dataSource.hasAnyConnections || _dataSource.isLoading || _tableController.isPendingReload);

    if (self.nothingToShowContainerView.hidden && !showContainerView) {
        self.nothingToShowContainerView.hidden = NO;
        [[self nothingToShowController] viewDidAppear:NO];
        // Make sure the arrow shows, even if the view was previously loaded.
        // Since making the view unhidden does not call viewDidLoad, we need
        // to start the animation manually in this case, in case it already ran before
        // won't be shown again unless viewDidAppear is called.
    }

    self.containerView.hidden = !showContainerView;
    self.nothingToShowContainerView.hidden = showContainerView;
}

- (FollowConnectionsNothingToShowViewController *)nothingToShowController {
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:[FollowConnectionsNothingToShowViewController class]]) {
            return (FollowConnectionsNothingToShowViewController *) vc;
        }
    }

    return nil;
}


- (IBAction)didClickInviteButton:(id)sender {
    if (_inviteMode) {
        // TODO: Remove this hack, once you build a good way into the the control
        MBContactCollectionView *collectionView = [_pickerView performSelector:@selector(contactCollectionView)];
        NSIndexPath *entryCellIndexPath = [collectionView performSelector:@selector(entryCellIndexPath)];
        MBContactCollectionViewEntryCell *entryCell = (MBContactCollectionViewEntryCell *) [collectionView cellForItemAtIndexPath:entryCellIndexPath];
        NSString *trimmedString = [entryCell.text stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray *selectedContacts = [collectionView performSelector:@selector(selectedContacts)];

        // Need to simulate hitting enter
        if (trimmedString.length > 0) {
            // There is unentered text, try to add it as a contact
            if (trimmedString.isValidEmailAddress) {
                InviteContact *contact = [[InviteContact alloc] init];
                contact.emailAddress = trimmedString;
                // Need to add right to collection view so the keyboard does not pop up again.
                if (![selectedContacts containsObject:contact]) [selectedContacts addObject:contact];
                [entryCell reset];
                [entryCell removeFocus];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Invalid email address, please correct it"
                                           delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                return;
            }
        }

        if (_pickerView.contactsSelected.count > 0) [self sendInvites];
        self.inviteMode = NO;
    } else {
        if ([PFUser currentUser].email) {
            // The user has taken an action to invite people, thus we can allow the address book prompt
            self.inviteMode = YES;
            [self.addressBookDataSource ensureAddressBookOpenWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [UsageAnalytics trackError:error forOperationNamed:@"openAddressBook"];
                }
                if (succeeded) {
                    [self.pickerView reloadData];
                } else {
                    // UIAlert, if not shown already.
                    if (!_showedPermissionWarning) {
                        _showedPermissionWarning = YES;
                        [[[UIAlertView alloc] initWithTitle:@"No Access To Contacts" message:@"You will need to enter email addresses manualy. To enable picking from your contacts go to the Privacy->Contacts section in the Settings app and enable access for DataParenting." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    }
                }
            }];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Signup Now?" message:@"You need to SIGN-UP to use the Monitor feature."
                                       delegate:nil cancelButtonTitle:@"Maybe Later" otherButtonTitles:@"Lets Do It!", nil]
                    showWithButtonBlock:^(NSInteger buttonIndex) {
                        [UsageAnalytics trackSignupTrigger:@"promptForMonitorFeature" withChoice:buttonIndex == 1];
                        if (buttonIndex == 1) {
                            // Yes
                            [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:^(BOOL succeeded, NSError *error) {
                                [UsageAnalytics trackSignupDecisionOnScreen:@"Monitors" withChoice:succeeded];
                                if (succeeded) [self didClickInviteButton:sender];
                            }];
                        } else {
                            [UsageAnalytics trackSignupDecisionOnScreen:@"Monitors" withChoice:NO];
                        }
                    }];
        }
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
    [self setInviteMode:inviteMode withAnimation:YES];
}

- (void)setInviteMode:(BOOL)inviteMode withAnimation:(BOOL)animates {
    _inviteMode = inviteMode;
    if (_inviteMode) {
        self.inviteButton.style = UIBarButtonItemStyleDone;
        self.inviteButton.title = @"Done";
        self.inviteButton.image = nil;
        self.pickerView.hidden = NO;
        [self.pickerView reloadData];
        [self.pickerView becomeFirstResponder];
        self.pickerHeightConstraint.constant = self.pickerView.currentContentHeight;
    } else {
        [self.pickerView resignFirstResponder];
        self.pickerHeightConstraint.constant = 0;
        self.inviteButton.style = UIBarButtonItemStylePlain;
        self.inviteButton.title = nil;
        self.inviteButton.image = [UIImage imageNamed:@"createButton"];
    }

    if (animates) {
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [self.view layoutIfNeeded];
            self.nothingToShowContainerView.alpha = _inviteMode ? 0 : 1;
        }];
    }

}

- (void)followConnectionsDataSourceDidChange {
    [self updateBadgeFromCurrent];
    [self updateContainerViewState];
}

- (void)urlOpened:(NSNotification *)notice {
    NSURL *url = notice.object;
    if ([url.host isEqualToString:kDDPushNotificationTypeFollowConnection]) {
        self.navigationController.tabBarController.selectedViewController = self.navigationController;
    }
}

- (void)gotPushNotification:(NSNotification *)notice {
    // First check if it is a tipsNotification, ignore if not.
    if ([kDDPushNotificationTypeFollowConnection isEqualToString:notice.userInfo[kDDPushNotificationField_CData][kDDPushNotificationField_Type]]) {
        [_dataSource loadObjects];
        if (((NSNumber *) notice.userInfo[kDDPushNotificationField_OpenedFromBackground]).boolValue) {
            // Make this the currently selected tab
            self.navigationController.tabBarController.selectedViewController = self.navigationController;
        }
    }
}

- (void)updateBadgeFromCurrent {
    NSInteger waitingInvitationsCount = [_dataSource connectionsInSection:FollowConnectionDataSourceSection_WaitingToAccept].count;
    NSInteger oldBadgeNumber = self.navigationController.tabBarItem.badgeValue.integerValue;
    if (waitingInvitationsCount > oldBadgeNumber) {
        // Play sound
        AudioServicesPlaySystemSound(1003);
    }

    // TODO: remove this after v1.3!
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"v1.3MonitorTabTouched"]) {
        self.navigationController.tabBarItem.badgeValue = @"New";
    } else {
        self.navigationController.tabBarItem.badgeValue = waitingInvitationsCount > 0 ? @(waitingInvitationsCount).stringValue : nil;
    }
}

- (void)appEnterForeground:(NSNotification *)notice {
    [_dataSource loadObjects];
    [_addressBookDataSource clearCache]; // Make sure any changes made in address book are now reflected
    [self.pickerView reloadData];
    [self.pickerView resignFirstResponder];
}

- (void)sendInvites {
    // Since we are sending invites, we can make the intro screen go away right away.
    self.nothingToShowContainerView.hidden = YES;
    self.containerView.hidden = NO;

    // We need a name from which to send the invite.
    [self makeBestAttemptToPopulateSendersFullNameWithBlock:^(NSString *string, NSError *error) {
        NSMutableArray *inviteArray = [[NSMutableArray alloc] initWithCapacity:_pickerView.contactsSelected.count];
        for (InviteContact *contact in _pickerView.contactsSelected) {
            NSAssert(contact.emailAddress, @"Unexpected nil emailAddress");
            [inviteArray addObject:@{
                    @"sendToName" : contact.fullName ? contact.fullName : [NSNull null],
                    @"sendToEmail" : contact.emailAddress.lowercaseString
            }];
        }
        [UsageAnalytics trackFollowConnectionInviteSent:[inviteArray count]];
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
    if(!self.pickerView.hidden) {
        self.pickerHeightConstraint.constant = newHeight;
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}


@end

