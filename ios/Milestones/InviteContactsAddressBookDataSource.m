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

#pragma mark - MBContactPickerDataSource

// Use this method to give the contact picker the entire set of possible contacts.  Required.
- (NSArray *)contactModelsForContactPicker:(MBContactPicker *)contactPickerView {
    if (!_orderedContacts) [self populateContactsWithEmailAddress];
    return _orderedContacts;
}

- (InviteContact *)findContactForEmailAddress:(NSString *)searchEmail {
    // Don't show warning when just trying to check addresses - just don't return anything.
    if (!_contactsByEmail) [self populateContactsWithEmailAddress];
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
    if (email) {
        [_excludeContactsWithEmail removeObject:email];
        [self clearCache];
    }
}

- (BOOL)ensureAddressBookOpenIfAlreadyAuthorized {

    if (_addressBook) {
        return YES;
    }

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        CFErrorRef error = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (error) {
            if (addressBook) CFRelease(addressBook);
            return NO;
        }
        _addressBook = addressBook;
        return YES;
    } else {
        return NO;
    }
}

- (void)ensureAddressBookOpenWithBlock:(PFBooleanResultBlock)block {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        // present the user the UI that requests permission to contacts ...
        CFErrorRef error = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (error) {
            if (addressBook) CFRelease(addressBook);
            block(NO, (__bridge NSError *) error);
            return;
        } else {
            ABAddressBookRequestAccessWithCompletion(addressBook, ^void(bool granted, CFErrorRef cfError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        _addressBook = addressBook;
                    } else if (addressBook) {
                        [UsageAnalytics trackUserDeniedAddressBookAccess];
                        CFRelease(addressBook);
                    }
                    block(granted, (__bridge NSError *) error);
                });
            });
        }
    } else {
        block([self ensureAddressBookOpenIfAlreadyAuthorized], nil);
    }
}



#pragma mark - private


- (void)populateContactsWithEmailAddress {

    if (![self ensureAddressBookOpenIfAlreadyAuthorized]) return;

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

@end