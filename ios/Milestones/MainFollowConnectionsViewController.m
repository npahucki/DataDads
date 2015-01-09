//
//  InvitationsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <MBContactPicker/MBContactPicker.h>
#import "MainFollowConnectionsViewController.h"
#import "InviteContactsAddressBookDataSource.h"
#import "FollowConnectionsTableViewController.h"
#import "NSString+EmailAddress.h"


@interface MainFollowConnectionsViewController ()
@end

@implementation MainFollowConnectionsViewController {
    FollowConnectionsTableViewController * _followConnectionsTableController;
    InviteContactsAddressBookDataSource *_addressBookDataSource;
    BOOL _inviteMode;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _addressBookDataSource = [[InviteContactsAddressBookDataSource alloc] init];
    self.pickerView.layer.borderColor = [UIColor appNormalColor].CGColor;
    self.pickerView.layer.borderWidth = 1;
    self.pickerView.allowsCompletionOfSelectedContacts = NO;
    self.pickerView.prompt = @"Invite:";
    self.pickerView.maxVisibleRows = 5;
    self.pickerView.delegate = self;
    self.pickerView.datasource = _addressBookDataSource;
    [[MBContactCollectionViewContactCell appearance] setTintColor:[UIColor appNormalColor]];
    self.inviteMode = NO;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[FollowConnectionsTableViewController class]]) {
        _followConnectionsTableController = (FollowConnectionsTableViewController*)segue.destinationViewController;
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

- (void)sendInvites {

    NSMutableArray *inviteArray = [[NSMutableArray alloc] initWithCapacity:_pickerView.contactsSelected.count];
    for (InviteContact *contact in _pickerView.contactsSelected) {
        NSAssert(contact.emailAddress, @"Unexpected nill emailAddress");
        [inviteArray addObject:@{
                @"sendToName" : contact.fullName ? contact.fullName : [NSNull null],
                @"sendToEmail" : contact.emailAddress
        }];
    }
    [PFCloud callFunctionInBackground:@"sendFollowInvitation"
                       withParameters:@{@"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                               @"invites" : inviteArray}
                                block:^(NSArray *objects, NSError *error) {
                                    if(error) {
                                        [UsageAnalytics trackError:error forOperationNamed:@"sendInvites"];
                                        [[[UIAlertView alloc] initWithTitle:@"Could Not Send Invites" message:@"There was an error trying to send the invites. Make sure you have an internet connection and try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                                    }

                                    // Show any invites in the window now.
                                    [_followConnectionsTableController loadObjects];
                                }];
}

#pragma mark - MBContactPickerDelegate

// Optional
- (void)contactCollectionView:(MBContactCollectionView *)contactCollectionView didSelectContact:(id <MBContactPickerModelProtocol>)model {
    NSLog(@"Did Select: %@", model.contactTitle);
}

// Optional
- (void)contactCollectionView:(MBContactCollectionView *)contactCollectionView didAddContact:(id <MBContactPickerModelProtocol>)model {
    NSLog(@"Did Add: %@", model.contactTitle);
}

// Optional
- (void)contactCollectionView:(MBContactCollectionView *)contactCollectionView didRemoveContact:(id <MBContactPickerModelProtocol>)model {
    NSLog(@"Did Remove: %@", model.contactTitle);
}

// NOTE: This method is named badly.
- (void)contactcollectionView:(MBContactCollectionView *)contactCollectionView didEnterCustomContact:(NSString *)text {
    if (text.isValidEmailAddress) {
        InviteContact *contact = [[InviteContact alloc] init];
        contact.emailAddress = text;
        [_pickerView addToSelectedContacts:contact];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Invalid email address, please correct it" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
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
