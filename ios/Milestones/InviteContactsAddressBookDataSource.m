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
}

- (void)dealloc {
    if (_addressBook) {
        CFRelease(_addressBook);
        _addressBook = nil;
    }
}

#pragma mark - MBContactPickerDataSource

// Use this method to give the contact picker the entire set of possible contacts.  Required.
- (NSArray *)contactModelsForContactPicker:(MBContactPicker *)contactPickerView {
    // TODO: Remove contacts with pending invites or already connected!
    return [self getContactsWithEmailAddress];
}

#pragma mark - private

- (NSArray *)getContactsWithEmailAddress {

    if (![self openAddressBook]) return nil;

    NSMutableArray *contacts = [[NSMutableArray alloc] init];

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
                InviteContact *contact = [[InviteContact alloc] init];
                contact.image = imagine;
                contact.fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                contact.emailAddress = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailAddresses, ii));
                [contacts addObject:contact];
            }
        }
        CFRelease(emailAddresses);
    }

    return contacts;
}

- (BOOL)openAddressBook {

    if (_addressBook) return YES; // already opened.

    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusDenied) {
        [self showNoAddressBookAccessMsg];
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
                    [self showNoAddressBookAccessMsg];
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
    [UsageAnalytics trackUserDeniedAddressBookAccess];
    [[[UIAlertView alloc] initWithTitle:@"No Access To Contacts" message:@"Since you have not allowed access to your contacts, we will NOT be able to help you pick them. You can still enter email addresses manualy. To enable picking from your contacts go to the Privacy->Contacts section in the Settings app and enable access for DataParenting." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


@end