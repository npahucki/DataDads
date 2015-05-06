//
// Created by Nathan  Pahucki on 4/30/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionUtils.h"
#import "InviteContactsAddressBookDataSource.h"
#import "SignUpOrLoginViewController.h"


@implementation FollowConnectionUtils

+ (void)makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource withBlock:(PFStringResultBlock)block {
    ParentUser *user = [ParentUser currentUser];
    if (!user.fullName.length) {
        // This is probably the most accurate one.
        user.fullName = [addressBookDataSource findContactForEmailAddress:user.email].fullName;
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


+ (void)makeBestAttemptToPopulateSendersFullNameWithAddressBookDataSource:(InviteContactsAddressBookDataSource *)addressBookDataSource {
    [self makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:addressBookDataSource withBlock:^(NSString *string, NSError *error) {
        // Dummy block
    }];
}

+ (void)ensureCurrentUserHasEmailPresentIn:(UIViewController *)viewController andRunBlock:(PFBooleanResultBlock)block {
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
                            [SignUpOrLoginViewController presentSignUpInController:viewController andRunBlock:^(BOOL succeeded, NSError *error) {
                                [UsageAnalytics trackSignupDecisionOnScreen:@"NoteMilestoneSharingOptions" withChoice:succeeded];
                                if (succeeded && ![ParentUser currentUser].hasEmail) {
                                    // They signed up (perhaps via facebook) but did not allow access to their email address
                                    [self ensureCurrentUserHasEmailPresentIn:viewController andRunBlock:block];
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
                                [self ensureCurrentUserHasEmailPresentIn:viewController andRunBlock:block];
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


@end