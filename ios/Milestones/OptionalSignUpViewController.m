//
//  OptionalSignUpViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/9/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "OptionalSignUpViewController.h"

@interface OptionalSignUpViewController ()

@end

@implementation OptionalSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIButton appearanceWhenContainedIn:[self class], nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [UIButton appearanceWhenContainedIn:[self class], nil].titleLabel.font = [UIFont fontForAppWithType:Bold andSize:14.0];
    self.navigationItem.prompt = [self.navigationItem.prompt stringByAppendingString:@" (Optional)"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.emailTextField.text = [ParentUser currentUser].email;
    self.emailTextField.enabled = ![ParentUser currentUser].isAuthenticated;
    self.passwordTextField.enabled = ![ParentUser currentUser].isAuthenticated;
    self.signupWithFacebookButton.enabled = ![ParentUser currentUser].isAuthenticated;
}

- (IBAction)didClickNextButton:(id)sender {
    // If username and password are filled out, then use this as signup data.

    if (![PFUser currentUser].isAuthenticated && self.emailTextField.text.length) {
        if (self.passwordTextField.text.length < 4) {
            [[[UIAlertView alloc]                                                             initWithTitle:@"Password Required" message:
                    @"If you want to sign in now, please provide a password of four or characters" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailTest evaluateWithObject:_emailTextField.text]) {
            [[[UIAlertView alloc]                                                  initWithTitle:@"Valid Email Address Required" message:
                    @"If you want to sign in now, please provide a valid email address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        };

        if (![Reachability isParseCurrentlyReachable]) {
            [[[UIAlertView alloc]                                                           initWithTitle:@"Network Connection Required" message:
                    @"Please make sure that you are connected to a network before pressing Next" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

        // Try to signup using the provided info.
        [self showInProgressHUDWithMessage:@"Signing up..." andAnimation:YES andDimmedBackground:YES withCancel:NO];
        PFUser *user = [PFUser object];
        user.email = self.emailTextField.text;
        user.username = self.emailTextField.text;
        user.password = self.passwordTextField.text;
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSString *msg;
                if ([error.domain isEqualToString:@"Parse"] && (error.code == 202 || error.code == 203)) {
                    msg = @"The email address is already associated with an account. "
                            "Please tap the Back button and log in with that email instead of creating a new account";

                } else {
                    msg = @"Could not sign you up now. Trying again now or later may correct the problem";
                }
                [self showErrorThenRunBlock:error withMessage:msg andBlock:nil];
            } else if (succeeded) {
                user.ACL = [PFACL ACLWithUser:user];
                [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"parse"];
                [self showSuccessThenRunBlock:^{
                    [self performSegueWithIdentifier:kDDSegueShowAboutYou sender:self]; // next page
                }];
            } else {
                [self                                                                   showErrorThenRunBlock:error withMessage:@"Signup failed for an unknown reason. "
                        "Please try again a little later or contact support if the problem persists" andBlock:nil];
            }
        }];
    } else {
        // Just go to the next page
        [self performSegueWithIdentifier:kDDSegueShowAboutYou sender:self]; // next page
    }
}

- (IBAction)didClickLoginWithFacebook:(id)sender {
    [self showInProgressHUDWithMessage:@"Authenticating..." andAnimation:YES andDimmedBackground:YES withCancel:NO];
    [PFFacebookUtils logInWithPermissions:@[@"user_about_me", @"email"] block:^(PFUser *user, NSError *error) {
        [UsageAnalytics trackUserLinkedWithFacebook:(ParentUser *) user forPublish:NO withError:error];
        if (error) {
            [self showErrorThenRunBlock:error withMessage:nil andBlock:^{
                if (![PFFacebookUtils showAlertIfFacebookDisplayableError:error]) {
                    [[[UIAlertView alloc] initWithTitle:@"Could Not Signin" message:@"Something went wrong while signing"
                                    " into Facebook, trying again now or later may fix the problem"
                                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        } else {
            if (user) {
                // Set the user's email and username to facebook email
                user.ACL = [PFACL ACLWithUser:user];
                [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser *) user block:nil];
                [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"facebook"];
                [self showSuccessThenRunBlock:^{
                    [self performSegueWithIdentifier:kDDSegueShowAboutYou sender:self]; // next page
                }];
            } // else user canceled
        }
    }];

}


@end
