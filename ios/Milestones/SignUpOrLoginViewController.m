//
//  SignupViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SignUpOrLoginViewController.h"
#import "NSString+EmailAddress.h"
#import "UIResponder+FirstResponder.h"
#import "UIViewController+MBProgressHUD.h"

@interface SignUpOrLoginViewController ()
@property(strong, nonatomic) MBProgressHUD *hud;
@property(copy) PFBooleanResultBlock block;

@end

@implementation SignUpOrLoginViewController {
    BOOL _isKeyboardShowing;
    CGRect _originalFrame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginWithFacebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitleColor:[UIColor appNormalColor] forState:UIControlStateNormal];

    self.actionButton.titleLabel.font = self.loginWithFacebookButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    self.forgotPasswordButton.titleLabel.font = [UIFont fontForAppWithType:Light andSize:21];
    self.emailAddressTextField.font = self.passwordTextField.font = [UIFont fontForAppWithType:Book andSize:19];
    self.titleLabel.font = [UIFont fontForAppWithType:Book andSize:29];

    if (self.loginMode) {
        self.forgotPasswordButton.hidden = NO;
        self.titleLabel.text = @"Login";
        [self.actionButton setTitle:self.titleLabel.text forState:UIControlStateNormal];
        [self.loginWithFacebookButton setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    } else {
        self.forgotPasswordButton.hidden = YES;
        self.titleLabel.text = @"Sign Up";
        [self.actionButton setTitle:self.titleLabel.text forState:UIControlStateNormal];
        [self.loginWithFacebookButton setTitle:@"Signup using Facebook" forState:UIControlStateNormal];
    }

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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)didClickCloseButton:(id)sender {
    [self didCancel];
}

- (IBAction)didClickForgotPasswordButton:(id)sender {
    NSAssert(_loginMode, @"Did not expect click on forgot password button while in signup mode!");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Password" message:@"Please enter the email associated with your account:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [alert showEmailPromptWithBlock:^(NSString *email, NSError *emailError) {
        if (email.length) {
                [self showStartProgress];
            [PFUser requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
                    if (error || !succeeded) {
                        [self showErrorThenRunBlock:error withMessage:@"We could not reset your password usng the email that you provided. Try entering your email address again." andBlock:nil];
                    } else {
                        [self showSuccessAndRunBlock:^{
                            [[[UIAlertView alloc] initWithTitle:@"Great!" message:@"Check your email for the reset link. Once you're done, try to login again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                        }];
                    }
                }];
        }
    }];
}

- (IBAction)didClickFacebookButton:(id)sender {
    if (![Reachability showAlertIfParseNotReachable]) {
        [self showStartProgress];
        if (_loginMode) {
            [self doFacebookLogin];
        } else {
            [self doFacebookSignup];
        }
    }
}

- (void)doFacebookSignup {
    ParentUser *user = [ParentUser currentUser];
    NSAssert(user && !user.isLoggedIn, @"Expected to work with an existing anonymous user");
    // Since this is ONLY ever used AFTER an anonymous user is created, we use the link here
    // to avoid the odd case when using login
    [PFFacebookUtils linkUser:user permissions:@[@"email"] block:^(BOOL success, NSError *error) {
        [UsageAnalytics trackUserLinkedWithFacebook:user forPublish:NO withError:error];
        if (error) {
            [UsageAnalytics trackUserSignupError:error usingMethod:@"facebook"];
            [self didFailWithError:error];
        } else {
            if (success) {
                [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"facebook"];
                // Set the user's email and username to facebook email
                [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser *) user block:nil];
                [self didLoginOrSignUpUser:user];
            } else {
                [self didCancel];
            }
        }
    }];
}

- (void)doFacebookLogin {
    NSAssert([ParentUser currentUser] == nil, @"Expected to work with an NIL user for login");
    [PFFacebookUtils logInWithPermissions:@[@"email"] block:^(PFUser *user, NSError *error) {
        if (error) {
            [self didFailWithError:error];
        } else {
            [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser *) user block:^(BOOL succeeded, NSError *error2) {
                if (user) {
                    [self didLoginOrSignUpUser:user];
                } else {
                    [self didCancel];
                }
            }];
        }
    }];
}

- (IBAction)didTapBackground:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)didClickActionButton:(id)sender {
    [self.view endEditing:NO];

    NSString *password = self.passwordTextField.text ?: @"";
    NSString *email = self.emailAddressTextField.text ?: @"";

    if (![email isValidEmailAddress]) {
        [[[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
            [self.emailAddressTextField becomeFirstResponder];
        }];
        return;
    }

    if (_loginMode) {
        [self doLoginWithEmail:email andPassword:password];
    } else {
        [self doSignupWithEmail:email andPassword:password];
    }
}

- (void)doLoginWithEmail:(NSString *)email andPassword:(NSString *)password {
    NSAssert(_loginMode, @"Expected to be in login mode!");
    if (![Reachability showAlertIfParseNotReachable]) {
        [self showStartProgress];
        [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
            if (user) {
                [self didLoginOrSignUpUser:user];
            } else {
                [UsageAnalytics trackError:error forOperationNamed:@"parseLogin"];
                [self didFailWithError:error];
            }
        }];
    }
}

- (void)doSignupWithEmail:(NSString *)email andPassword:(NSString *)password {
    NSAssert(!_loginMode, @"Expected to be in signup mode!");
    if ([password length] < 4) {
        [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Password must be at least 4 characters." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
            [self.passwordTextField becomeFirstResponder];
        }];
    } else if (![Reachability showAlertIfParseNotReachable]) {
        [self showStartProgress];
        PFUser *user = [PFUser user];
        user.username = email;
        user.email = email;
        user.password = password;
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"parse"];
                [self didLoginOrSignUpUser:user];
            } else {
                [UsageAnalytics trackUserSignupError:error usingMethod:@"parse"];
                [self didFailWithError:error];
            }
        }];
    }
}

#pragma mark Methods to deal with moving view for keyboard

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification {


    if ([UIResponder currentFirstResponder] == self.passwordTextField || [UIResponder currentFirstResponder] == self.emailAddressTextField) {


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
        CGFloat bottomOfActionButton = self.actionButton.frame.size.height + self.actionButton.frame.origin.y;
        if (bottomOfActionButton > self.view.frame.size.height - kbSize.height) {
            [UIView
                    animateWithDuration:0.5
                             animations:^{
                                 self.view.frame = CGRectMake(0, _originalFrame.origin.y - kbSize.height + (_originalFrame.size.height - bottomOfActionButton), _originalFrame.size.width, _originalFrame.size.height);
                             }];
        }
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
    if (textField == self.emailAddressTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.view endEditing:NO];
        return YES;
    }
    return NO;
}


#pragma mark Custom HUD Methods.

- (void)showHUD:(BOOL)animated {
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
        self.hud.animationType = MBProgressHUDAnimationFade;
        self.hud.dimBackground = NO;
        self.hud.completionBlock = nil;
    }
    [self.hud show:animated];
    self.hud.hidden = NO;
}

- (void)showHUDWithMessage:(NSString *)msg andAnimation:(BOOL)animated {
    [self showHUD:animated];
    self.hud.labelText = msg;
}

- (void)showStartProgress {
    [self showHUDWithMessage:@"Just a sec please..." andAnimation:YES];
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

- (void)showSuccessAndRunBlock:(dispatch_block_t)block {
    [self showHUD:NO];
    UIImageView *animatedView = [self animatedImageView:@"success" frames:9];
    self.hud.customView = animatedView;
    [animatedView startAnimating];
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.completionBlock = block;
    [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

- (void)showError:(NSError *)error {
    UIImageView *animatedView = [self animatedImageView:@"error" frames:9];
    self.hud.customView = animatedView;
    self.hud.mode = MBProgressHUDModeCustomView;
    [animatedView startAnimating];
    __weak SignUpOrLoginViewController *weakSelf = self;
    self.hud.completionBlock = ^{
        NSString *title = @"Sign Up Error";
        if ([[error domain] isEqualToString:PFParseErrorDomain]) {
            NSInteger errorCode = [error code];
            NSString *message = nil;
            UIResponder *responder = nil;

            if (errorCode == kPFErrorInvalidEmailAddress) {
                message = @"The email address is invalid. Please enter a valid email.";
                responder = weakSelf.emailAddressTextField;
//            } else if (errorCode == kPFErrorUsernameMissing || error.code == kPFErrorUserEmailMissing) {
            } else if (errorCode == kPFErrorUserPasswordMissing) {
                message = @"Please enter a password.";
                responder = weakSelf.passwordTextField;
            } else if (errorCode == kPFErrorObjectNotFound) {
                message = @"Invalid email or password";
                responder = weakSelf.emailAddressTextField;
            } else if (errorCode == kPFErrorUsernameTaken || error.code == kPFErrorUserEmailTaken) {
                message = @"The email address '%@' is already in use. Please use a different email address (or contact support if you are the owner of this email address).";
                message = [NSString stringWithFormat:message, weakSelf.emailAddressTextField.text];
                responder = weakSelf.emailAddressTextField;
            } else if (errorCode == kPFErrorFacebookAccountAlreadyLinked) {
                message = @"Your facebook account is already linked to another account. Contact support if you want to discard the other account and link with this one.";
                message = [NSString stringWithFormat:message, weakSelf.emailAddressTextField.text];
            }

            if (message != nil) {
                [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                    [responder becomeFirstResponder];
                }];
                return;
            }
        }

        // Show the generic error alert, as no custom cases matched before
        [[[UIAlertView alloc] initWithTitle:title message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    };
    [self.hud hide:NO afterDelay:1.5];
}

+ (void)presentSignUpInController:(UIViewController *)vc andRunBlock:(PFBooleanResultBlock)block {
    NSAssert(![ParentUser currentUser].isLoggedIn, @"Can't sign up a logged in user!");
    SignUpOrLoginViewController *signupVc = [vc.storyboard instantiateViewControllerWithIdentifier:@"signupViewController"];
    signupVc.block = block;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [vc presentViewController:signupVc animated:YES completion:nil];
}

- (UIImageView *)animatedImageView:(NSString *)imageName frames:(int)count {
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@-%d.png", imageName, i]]];
    }
    UIImageView *view = [[UIImageView alloc] initWithImage:images[count - 1]];
    view.animationImages = images;
    view.animationDuration = .75;
    view.animationRepeatCount = 1;
    return view;
}

# pragma Signup Notification methods

- (void)didCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (_block) _block(NO, nil);
}

- (void)didLoginOrSignUpUser:(PFUser *)user {
    [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    if (!user.ACL) {
        user.ACL = [PFACL ACLWithUser:user];
        [user saveEventually];
    }
    [self showSuccessAndRunBlock:^{
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter]                            postNotificationName:
                _loginMode ? kDDNotificationUserLoggedIn : kDDNotificationUserSignedUp object:user];
        if (_block) _block(YES, nil);
    }];
}

- (void)didFailWithError:(NSError *)error {
    [self showError:error];
    if (_block) _block(NO, error);
}


@end
