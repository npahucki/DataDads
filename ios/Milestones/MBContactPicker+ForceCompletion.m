//
// Created by Nathan  Pahucki on 3/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "MBContactPicker+ForceCompletion.h"
#import "InviteContactsAddressBookDataSource.h"
#import "NSString+EmailAddress.h";


@implementation MBContactPicker (ForceCompletion)

- (BOOL)forcePendingTextEntry {
    MBContactCollectionView *collectionView = [self performSelector:@selector(contactCollectionView)];
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
            return NO;
        }
    }

    return YES;
}


@end