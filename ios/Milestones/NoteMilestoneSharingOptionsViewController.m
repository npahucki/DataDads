//
//  NoteMilestoneSharingOptionsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSharingOptionsViewController.h"
#import "NoteMilestoneSharingTableViewController.h"
#import "FollowConnectionsDataSource.h"
#import "InviteContactsAddressBookDataSource.h"
#import "NSString+EmailAddress.h"
#import "MBContactPicker+ForceCompletion.h"
#import "SignUpOrLoginViewController.h"
#import "NSDate+Utils.h"
#import "NoteMilestoneViewController.h"

@interface NoteMilestoneSharingOptionsViewController ()
@property(readonly) InviteContactsAddressBookDataSource *addressBookDataSource;
@end

@implementation NoteMilestoneSharingOptionsViewController {
    NoteMilestoneSharingTableViewController *_sharingTableViewController;
    InviteContactsAddressBookDataSource *_addressBookDataSource;
    FollowConnectionsDataSource *_followConnectionsDataSource;
    BOOL _inviteMode;
    BOOL _hasChangedSharingSettings;
    BOOL _rightBarButtonOldEnabledState;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.font = [UIFont fontForAppWithType:Book andSize:22.0F];
    self.selectFollowersLabel.font = [UIFont fontForAppWithType:Book andSize:16.0F];
    self.inviteButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:18.0F];
    self.dontShowAgainButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.dontShowAgainButton.titleLabel.minimumScaleFactor = 0.5F;

    BOOL enableFacebook = ParentUser.currentUser.autoPublishToFacebook && [PFFacebookUtils userHasAuthorizedPublishPermissions:ParentUser.currentUser];
    [self.enableFacebookButton setOn:enableFacebook animated:NO];

    [self.enableFollowersSwitch setOn:NO animated:NO];
    [_sharingTableViewController loadObjects];

    self.pickerView.layer.borderColor = [UIColor appNormalColor].CGColor;
    self.pickerView.layer.borderWidth = 1;
    self.pickerView.allowsCompletionOfSelectedContacts = NO;
    self.pickerView.maxVisibleRows = 5;
    self.pickerView.prompt = @""; // Note
    self.pickerView.delegate = self;
    self.pickerView.datasource = self.addressBookDataSource;
    [[MBContactCollectionViewContactCell appearance] setTintColor:[UIColor appNormalColor]];

    self.pickerView.hidden = YES; // Start hidden so we don't adjust the size during the delegate method, until the user has initially pressed the button to expand.
    self.pickerHeightConstraint.constant = 0;
    [self updateAchievementSharingOptions];
    [self updateContainerViewState];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followConnectionsDataSourceDidLoad)
                                                 name:kDDNotificationFollowConnectionsDataSourceDidLoadObjects
                                               object:self.followConnectionsDataSource];


}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NoteMilestoneSharingTableViewController class]]) {
        _sharingTableViewController = (NoteMilestoneSharingTableViewController *) segue.destinationViewController;
        _sharingTableViewController.contactsDataSource = self.addressBookDataSource;
        _sharingTableViewController.followConnectionsDataSource = self.followConnectionsDataSource;
    }
}

- (IBAction)didClickDontShowAgainButton:(UIButton *)sender {
    [ParentUser currentUser].suppressAutoShowNoteMilestoneShareScreen = YES;
    sender.selected = YES;
    [UIView animateWithDuration:1.0F animations:^{
        sender.alpha = 0.0;
    }                completion:^(BOOL finished) {
        sender.hidden = YES;
    }];
}

- (void)followConnectionsDataSourceDidLoad {
    for (FollowConnection *fc in [self.followConnectionsDataSource
            connectionsInSection:FollowConnectionDataSourceSection_Connected]) {
        [self.addressBookDataSource addExcludeContactWithEmail:fc.otherPartyEmail];
    }
    [self.pickerView reloadData];
    if (!_hasChangedSharingSettings) {
        BOOL enableFollowers = _sharingTableViewController.hasContacts; // If there are followers, always default to on.
        [self.enableFollowersSwitch setOn:enableFollowers animated:NO];
    }
    [self updateContainerViewState];
}

- (IBAction)didChangeEnableFacebookSwitch:(id)sender {
    _hasChangedSharingSettings = YES;
    if (self.enableFacebookButton.on) {
        [PFFacebookUtils ensureHasPublishPermissions:ParentUser.currentUser block:^(BOOL succeeded, NSError *error) {
            if (!succeeded) [self.enableFacebookButton setOn:NO animated:YES];
            if (error) {
                [PFFacebookUtils showFacebookErrorAlert:error];
            }
        }];
    }

    // This is local preference settings
    ParentUser.currentUser.autoPublishToFacebook = self.enableFacebookButton.on;
    [self updateContainerViewState];

}

- (IBAction)didChangeFollowersSwitch:(id)sender {
    _hasChangedSharingSettings = YES;
    if (self.enableFollowersSwitch.on) {
        [self ensureCurrentUserHasEmailAndRunBlock:^(BOOL success, NSError *emailError) {
            [self updateContainerViewState];
            if (success) {
                // If there are currently no followers, then automatically start invite mode.
                if (!_sharingTableViewController.hasContacts) [self setInviteMode:YES];
            } else {
                [self.enableFollowersSwitch setOn:NO animated:YES];
            }
            [self updateContainerViewState];
        }];
    } else {
        [self setInviteMode:NO];
    }

    [self updateContainerViewState];
}

- (IBAction)didClickInviteButton:(id)sender {
    NSAssert(self.enableFollowersSwitch.on, @"Expected that you can only click on invite when the enable followers is enabled");
    if (_inviteMode) {
        if (![_pickerView forcePendingTextEntry]) return;
        [self makeBestAttemptToPopulateSendersFullName];
        for (InviteContact *contact in _pickerView.contactsSelected) {
            [_sharingTableViewController addFollowConnectionContact:contact];
            [self.addressBookDataSource addExcludeContactWithEmail:contact.emailAddress];
        }
        self.inviteMode = NO;
    } else {
        self.inviteMode = YES;
    }
}

- (void)viewDidFinishSlidingOut:(UIViewController *)slidingView over:(UIViewController *)otherVc {
    [((NoteMilestoneViewController *) otherVc) updateAchievementFromInputs];
    if (!_hasChangedSharingSettings && [self isAchievementOld]) {
        // Default sharing to off if achievement is old.
        [self.enableFacebookButton setOn:NO animated:NO];
        [self.enableFollowersSwitch setOn:NO animated:NO];
        [self updateContainerViewState];
    }
}

- (void)viewDidFinishSlidingIn:(UIViewController *)slidingView over:(UIViewController *)otherVc {
    [self setInviteMode:NO withAnimation:NO];
}

- (void)updateContainerViewState {
    BOOL contactsEnabled = [_sharingTableViewController hasContacts] && self.enableFollowersSwitch.on;
    _sharingTableViewController.tableView.userInteractionEnabled = contactsEnabled;
    self.inviteButton.enabled = self.enableFollowersSwitch.on;
    self.dontShowAgainButton.hidden = _inviteMode || _sharingTableViewController.hasContacts ||
            [ParentUser currentUser].suppressAutoShowNoteMilestoneShareScreen || [ParentUser currentUser].autoPublishToFacebook;
    [UIView animateWithDuration:0.3 animations:^{
        self.selectFollowersLabel.alpha = contactsEnabled ? 1.0F : 0.2F;
        _sharingTableViewController.view.alpha = contactsEnabled ? 1.0F : 0.3F;
        self.inviteButton.alpha = self.inviteButton.enabled ? 1.0F : 0.2F;
    }];

}

- (InviteContactsAddressBookDataSource *)addressBookDataSource {
    if (!_addressBookDataSource) {
        _addressBookDataSource = [[InviteContactsAddressBookDataSource alloc] init];
        [_addressBookDataSource addExcludeContactWithEmail:[PFUser currentUser].email];
    }
    return _addressBookDataSource;
}

- (FollowConnectionsDataSource *)followConnectionsDataSource {
    if (!_followConnectionsDataSource) {
        _followConnectionsDataSource = [[FollowConnectionsDataSource alloc] init];
    }
    return _followConnectionsDataSource;
}


- (void)setInviteMode:(BOOL)inviteMode {
    [self setInviteMode:inviteMode withAnimation:YES];
}

- (void)setInviteMode:(BOOL)inviteMode withAnimation:(BOOL)animates {
    if (inviteMode) {
        [self ensureCurrentUserHasEmailAndRunBlock:^(BOOL success, NSError *emailError) {
            [self updateContainerViewState];
            if (success) {
                // The user has taken an action to invite people, thus we can allow the address book prompt
                _inviteMode = YES;
                [self.addressBookDataSource ensureAddressBookOpenWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        [UsageAnalytics trackError:error forOperationNamed:@"openAddressBook"];
                    }
                    if (succeeded) {
                        [self.pickerView reloadData];
                    }

                    [self.inviteButton setTitle:@"Done" forState:UIControlStateNormal];
                    _rightBarButtonOldEnabledState = self.parentViewController.navigationItem.rightBarButtonItem.enabled;
                    self.parentViewController.navigationItem.rightBarButtonItem.enabled = NO;
                    self.pickerView.hidden = NO;
                    [self.pickerView becomeFirstResponder];
                    // We need to collapse the top view so there is extra room to show the contacts.
                    [self setTopViewHeight:0 animated:animates];
                    [self setPickerHeight:self.pickerView.currentContentHeight animated:animates];
                    self.selectFollowersLabel.text = @"INVITE FOLLOWERS:";
                }];
            }
        }];
    } else {
        _inviteMode = NO;
        [self.inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
        if (_rightBarButtonOldEnabledState) {
            self.parentViewController.navigationItem.rightBarButtonItem.enabled = YES;
        }
        [self.pickerView resignFirstResponder];
        [self setPickerHeight:0 animated:animates];
        [self setTopViewHeight:108 animated:animates];
        self.selectFollowersLabel.text = @"SELECT FOLLOWERS:";
    }

    [self updateContainerViewState];
}

- (void)setPickerHeight:(CGFloat)height animated:(BOOL)animated {
    self.pickerHeightConstraint.constant = height;
    //[self.view setNeedsLayout];
    if (animated) {
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.view layoutIfNeeded];
    }

}

- (void)setTopViewHeight:(CGFloat)height animated:(BOOL)animated {
    self.topViewHeightConstraint.constant = height;
    if (animated) {
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.view layoutIfNeeded];
    }

}

- (BOOL)isAchievementOld {
    return ABS([self.achievement.completionDate daysDifferenceFromNow]) > 7;
}

- (void)updateAchievementSharingOptions {
    if (!_hasChangedSharingSettings && [self isAchievementOld]) {
        [self.enableFacebookButton setOn:NO animated:NO];
        [self.enableFollowersSwitch setOn:NO animated:NO];
        [self updateContainerViewState];
    }

    SharingOptions *sharingOptions = [[SharingOptions alloc] init];
    sharingOptions.sendToFollowers = _enableFollowersSwitch.on;
    sharingOptions.excludedFollowerEmails = _sharingTableViewController.excludedFollowerEmails;
    sharingOptions.additionalFollowerEmails = _sharingTableViewController.additionalFollowerEmails;
    self.achievement.sharingOptions = [sharingOptions asDictionary];

    self.achievement.sharedVia = SharingMediumNotShared |
            (SharingMediumFacebook & _enableFacebookButton.on) |
            (SharingMediumFollow & _enableFollowersSwitch.on);

}

- (void)makeBestAttemptToPopulateSendersFullName {
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
                }];
            } else {
                user.fullName = [ParentUser nameFromCurrentDevice];
            }
        }

        // Save if assigned
        if (user.fullName.length) [user saveEventually];
    }
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
                                [UsageAnalytics trackSignupDecisionOnScreen:@"NoteMilestoneSharingOptions" withChoice:succeeded];
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
        CGRect pickerRectInWindow = [self.view convertRect:contactPicker.frame fromView:nil];
        CGFloat newHeight = self.view.window.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight;
        [self setPickerHeight:newHeight animated:YES];
    }
}

// This delegate method is called to allow the parent view to decrease the size of
// the contact picker view to hide the search table view
- (void)didHideFilteredContactsForContactPicker:(MBContactPicker *)contactPicker {
    if (self.pickerHeightConstraint.constant > contactPicker.currentContentHeight) {
        [self setPickerHeight:contactPicker.currentContentHeight animated:YES];
    }
}

// This delegate method is invoked to allow the parent to increase the size of the
// collectionview that shows which contacts have been selected. To increase or decrease
// the number of rows visible, change the maxVisibleRows property of the MBContactPicker
- (void)contactPicker:(MBContactPicker *)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight {
    if (!self.pickerView.hidden) {
        [self setPickerHeight:newHeight animated:YES];
    }
}



@end
