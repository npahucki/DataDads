//
//  InvitationsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <CMPopTipView/CMPopTipView.h>
#import "MainFollowConnectionsViewController.h"
#import "InviteContactsAddressBookDataSource.h"
#import "FollowConnectionsTableViewController.h"
#import "NSString+EmailAddress.h"
#import "FollowConnectionsNothingToShowViewController.h"
#import "SignUpOrLoginViewController.h"
#import "CMPopTipView+WithStaticInitializer.h"


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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogAchievement:) name:kDDNotificationMilestoneNotedAndSaved object:nil];

    return self;
}

- (void)userDidLogOut {
    [_dataSource loadObjects];
    [_addressBookDataSource clearCache];
}

- (void)userDidLogAchievement:(NSNotification *)notification {
    // If they haven't opened the share tab yet...AND they have not been shown the message
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (!self.tipView && !([defs boolForKey:@"ShareTabTouched"] || [defs boolForKey:@"ShowedTutorialTip_ShareTab"])) {
        MilestoneAchievement *achievement = notification.object;
        if ([achievement.customTitle rangeOfString:@"born and is beautiful"].length == 0) {
            [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(showToastTip) userInfo:nil repeats:NO];
        }
    }
}

- (void)showToastTip {
    // Toggle popTipView when a standard UIButton is pressed
    NSString *msg = @"Automatically email your friends & family each new milestone!";
    self.tipView = [CMPopTipView instanceWithApplicationLookAndFeelAndMessage:msg];
    self.tipView.delegate = self;
    self.tipView.maxWidth = self.view.frame.size.width - 30;

    // HACK ALERT: There is no way to find the view for the tab bar item, and seemingly no way to
    // map the tabBarItem back to the view...so as long as we don't add anything after the
    // Share tab, this will keep working. Things can be added before with no problem.
    UIView *tabBarView = nil;
    for (UIView *view in self.tabBarController.tabBar.subviews) {
        if ([view isKindOfClass:[UIControl class]]) {
            // We want the last one....NOTE: This wil break if we add tabs after Share!!
            tabBarView = view;
        }
    }
    [self.tipView presentPointingAtView:tabBarView inView:self.tabBarController.view animated:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowedTutorialTip_ShareTab"];
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
    self.tipView = nil;
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShareTabTouched"];
    if (self.tipView) {
        [self.tipView dismissAnimated:NO];
        self.tipView = nil;
    }

    [_addressBookDataSource clearCache];
    [self updateContainerViewState];
    [self updateBadgeFromCurrent];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
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
    self.inviteButton.enabled = [ParentUser currentUser].hasEmail;
    BOOL showContainerView = [ParentUser currentUser].hasEmail && (_dataSource.hasAnyConnections || _dataSource.isLoading || _tableController.isPendingReload);

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
        [self ensureCurrentUserHasEmailAndRunBlock:^(BOOL success, NSError *emailError) {
            [self updateContainerViewState];
            if (success) {
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
            }
        }];
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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShareTabTouched"]) {
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

- (void)ensureCurrentUserHasEmailAndRunBlock:(PFBooleanResultBlock)block {
    if ([ParentUser currentUser].hasEmail) {
        block(YES, nil);
    } else {
        if (![ParentUser currentUser].isLoggedIn) {
            [[[UIAlertView alloc] initWithTitle:@"Signup Now?" message:@"You need to SIGN-UP to use the Share feature."
                                       delegate:nil cancelButtonTitle:@"Maybe Later" otherButtonTitles:@"Lets Do It!", nil]
                    showWithButtonBlock:^(NSInteger buttonIndex) {
                        [UsageAnalytics trackSignupTrigger:@"promptForShareFeature" withChoice:buttonIndex == 1];
                        if (buttonIndex == 1) {
                            // Yes
                            [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:^(BOOL succeeded, NSError *error) {
                                [UsageAnalytics trackSignupDecisionOnScreen:@"Share" withChoice:succeeded];
                                if (succeeded && ![ParentUser currentUser].hasEmail) {
                                    // They signed up (perhaps via facebook) but did not allow access to their email address
                                    [self ensureCurrentUserHasEmailAndRunBlock:block];
                                    return;
                                }
                                block(succeeded, error);
                            }];
                        } else {
                            [UsageAnalytics trackSignupDecisionOnScreen:@"Share" withChoice:NO];
                            block(NO, nil);
                        }
                    }];
        } else {
            // This can happen if they authenticated with a 3rd party, like facebook, but we did not get an email address
            // because they denied it, or the facebook account simply did not have an email address associated.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Required" message:@"Please enter your email address to use this feature:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
            [alert showEmailPromptWithBlock:^(NSString *email, NSError *error) {
                if (email) {
                    ParentUser *user = [ParentUser currentUser];
                    NSString *oldUsername = user.username;
                    user.email = user.username = email;
                    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *saveEmailError) {
                        if (succeeded) {
                            block(YES, error);
                        } else {
                            // Roll back username and password
                            user.email = nil;
                            user.username = oldUsername;
                            [[[UIAlertView alloc] initWithTitle:@"Could not save Email" message:saveEmailError.userInfo[@"error"]
                                                       delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                                [self ensureCurrentUserHasEmailAndRunBlock:block];
                            }];
                        }
                    }];
                    return;
                }
                block(email != nil, error);
            }];
        }
    }
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
    if (!self.pickerView.hidden) {
        self.pickerHeightConstraint.constant = newHeight;
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}


@end

