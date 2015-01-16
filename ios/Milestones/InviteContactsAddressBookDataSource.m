//
// Created by Nathan  Pahucki on 1/8/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "InviteContactsAddressBookDataSource.h"
#import <AddressBook/AddressBook.h>

@implementation InviteContact

- (NSString *)contactTitle {
    return self.fullName ? self.fullName : self.emailAddress;
}

- (NSString *)contactSubtitle {
    return self.emailAddress;
}

- (UIImage *)contactImage {
    return self.image;
}

@end


@implementation InviteContactsAddressBookDataSource {
    ABAddressBookRef _addressBook;
    BOOL _showedPermissionWarning;
    InviteContact *_contactForCurrentUser;
    NSDictionary *_contactsByEmail;
    NSArray *_orderedContacts;
    NSMutableSet *_excludeContactsWithEmail;
}

- (void)dealloc {
    if (_addressBook) {
        CFRelease(_addressBook);
        _addressBook = nil;
    }
}

- (InviteContact *)contactForCurrentUser {
    return _contactForCurrentUser;
}

#pragma mark - MBContactPickerDataSource

// Use this method to give the contact picker the entire set of possible contacts.  Required.
- (NSArray *)contactModelsForContactPicker:(MBContactPicker *)contactPickerView {
    if (!_orderedContacts) [self populateContactsWithEmailAddress];
    return _orderedContacts;
}

- (InviteContact *)findContactForEmailAddress:(NSString *)searchEmail {
    // Don't show warning when just trying to check addresses - just don't return anything.
    if (!_contactsByEmail && [self openAddressBook:NO]) {
        [self populateContactsWithEmailAddress];
    }
    return _contactsByEmail[searchEmail];
}

- (void)clearCache {
    _contactsByEmail = nil;
    _orderedContacts = nil;
}

- (void)addExcludeContactWithEmail:(NSString *)email {
    if (email) {
        if (!_excludeContactsWithEmail) _excludeContactsWithEmail = [[NSMutableSet alloc] init];
        [_excludeContactsWithEmail addObject:email];
        _contactsByEmail = nil; // force refresh
    }
}

- (void)removeExcludeContactWithEmail:(NSString *)email {
    [_excludeContactsWithEmail removeObject:email];
    [self clearCache];
}


#pragma mark - private


- (void)populateContactsWithEmailAddress {

    if (![self openAddressBook:YES]) return;

    NSMutableDictionary *contactsByEmail = [[NSMutableDictionary alloc] init];
    NSMutableArray *orderedContacts = [[NSMutableArray alloc] init];

    NSInteger numberOfPeople = ABAddressBookGetPersonCount(_addressBook);
    NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(_addressBook));

    for (NSUInteger i = 0; i < numberOfPeople; i++) {
        ABRecordRef person = (__bridge ABRecordRef) allPeople[i];
        ABMultiValueRef emailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        NSData *imgData = CFBridgingRelease(ABPersonCopyImageData(person));
        UIImage *imagine = [UIImage imageWithData:imgData];

        CFIndex numberOfEmailAddresses = ABMultiValueGetCount(emailAddresses);
        if (numberOfEmailAddresses > 0) { // Skip contacts without email address
            for (CFIndex ii = 0; ii < numberOfEmailAddresses; ii++) {
                NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailAddresses, ii));
                InviteContact *contact = [[InviteContact alloc] init];
                contact.image = imagine;
                contact.fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                contact.emailAddress = email;
                contactsByEmail[email] = contact;
                if (![_excludeContactsWithEmail containsObject:email]) [orderedContacts addObject:contact];
            }
        }
        CFRelease(emailAddresses);
    }

    _contactsByEmail = contactsByEmail;
    _orderedContacts = orderedContacts;
}

- (BOOL)openAddressBook:(BOOL)withWarning {

    if (_addressBook) return YES; // already opened.

    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusDenied) {
        if (withWarning) [self showNoAddressBookAccessMsg];
        return NO;
    }

    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) {
        [UsageAnalytics trackError:CFBridgingRelease(error) forOperationNamed:@"addressBookCreate"];
        if (addressBook) CFRelease(addressBook);
        return NO;
    }

    if (status == kABAuthorizationStatusNotDetermined) {
        // present the user the UI that requests permission to contacts ...
        ABAddressBookRequestAccessWithCompletion(addressBook, ^void(bool granted, CFErrorRef cfError) {
            if (cfError) {
                [UsageAnalytics trackError:CFBridgingRelease(cfError) forOperationNamed:@"addressBookAuthorization"];
            }
            if (granted) {
                _addressBook = addressBook;
            } else {
                // however, if they didn't give you permission, handle it gracefully, for example...
                dispatch_async(dispatch_get_main_queue(), ^{
                    // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                    if (withWarning) [self showNoAddressBookAccessMsg];
                });
                if (addressBook) CFRelease(addressBook);
            }
        });
    } else if (status == kABAuthorizationStatusAuthorized) {
        _addressBook = addressBook;
    }

    return _addressBook != nil;

}

- (void)showNoAddressBookAccessMsg {
    if (!_showedPermissionWarning) {
        _showedPermissionWarning = YES;
        [UsageAnalytics trackUserDeniedAddressBookAccess];
        [[[UIAlertView alloc] initWithTitle:@"No Access To Contacts" message:@"Since you have not allowed access to your contacts, we will NOT be able to help you pick them. You can still enter email addresses manualy. To enable picking from your contacts go to the Privacy->Contacts section in the Settings app and enable access for DataParenting." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}


@end