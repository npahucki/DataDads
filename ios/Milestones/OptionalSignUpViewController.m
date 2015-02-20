//
//  OptionalSignUpViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/9/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "OptionalSignUpViewController.h"
#import "NSString+EmailAddress.h"

@interface OptionalSignUpViewController ()

@end

@implementation OptionalSignUpViewController {
    BOOL _isKeyboardShowing;
    CGRect _originalFrame;
}

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification {
    UITextField *responder = self.passwordTextField;

    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    if (!_isKeyboardShowing) {
        _isKeyboardShowing = YES;
        _originalFrame = self.view.frame;
    }
    // NOTE: we use this instead of scroll view because working with autolayout and the scroll view is almost impossible
    // because we resize some content based on the size of the screen, and in scrollview, this means that the content is
    // as large as it can be, but is scrollable which is NOT what we want!

    // We just need to make sure the signup button is visible, even when the keyboard is present.
    CGFloat bottomOfResponder = responder.frame.size.height + responder.frame.origin.y;
    if (bottomOfResponder > self.view.frame.size.height - kbSize.height) {
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.view.frame = CGRectMake(0, _originalFrame.origin.y - kbSize.height + (_originalFrame.size.height - bottomOfResponder), _originalFrame.size.width, _originalFrame.size.height);
                         }];
    }

}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    _isKeyboardShowing = NO;
    [UIView
            animateWithDuration:0.5
                     animations:^{
                         self.view.frame = _originalFrame;
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.view endEditing:NO];
        return YES;
    }
    return NO;
}


- (IBAction)didClickNextButton:(id)sender {
    // If username and password are filled out, then use this as signup data.
    [self.view endEditing:YES];
    if (![PFUser currentUser].isAuthenticated && self.emailTextField.text.length) {
        if (self.passwordTextField.text.length < 4) {
            [[[UIAlertView alloc]                                                                  initWithTitle:@"Password Required" message:
                    @"If you want to sign in now, please provide a password of four or more characters" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

        if (![_emailTextField.text isValidEmailAddress]) {
            [[[UIAlertView alloc]                                                  initWithTitle:@"Valid Email Address Required" message:
                    @"If you want to sign in now, please provide a valid email address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        };

        [UsageAnalytics trackSignupTrigger:@"onboardingOptionalSignup" withChoice:YES];

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
                            "If you are owner of this email address, tap the Back button and login instead.";

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
        if (![PFUser currentUser].isAuthenticated) {
            [UsageAnalytics trackSignupTrigger:@"onboardingOptionalSignup" withChoice:NO];
        }
        [self performSegueWithIdentifier:kDDSegueShowAboutYou sender:self]; // next page
    }
}

- (IBAction)didClickLoginWithFacebook:(id)sender {
    [self showInProgressHUDWithMessage:@"Authenticating..." andAnimation:YES andDimmedBackground:YES withCancel:NO];
    [PFFacebookUtils logInWithPermissions:@[@"public_profile", @"email"] block:^(PFUser *user, NSError *error) {
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
