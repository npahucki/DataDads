//
//  SignupViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SignUpViewController.h"
#import "NSString+EmailAddress.h"

@interface SignUpViewController ()
@property (strong, nonatomic) MBProgressHUD * hud;
@property (copy) PFBooleanResultBlock block;

@end

@implementation SignUpViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginWithFacebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.signupButton.titleLabel.font = self.loginWithFacebookButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
}

-(BOOL) prefersStatusBarHidden {
    return YES;
}

- (IBAction)didClickCloseButton:(id)sender {
    [self didCancelSignUpUser];
}

- (IBAction)didClickFacebookButton:(id)sender {
    if (![Reachability showAlertIfParseNotReachable]) {
        [self showStartSignUpProgress];
        [PFFacebookUtils logInWithPermissions:@[@"user_about_me", @"email"] block:^(PFUser *user, NSError *error) {
            [UsageAnalytics trackUserLinkedWithFacebook:(ParentUser *) user forPublish:NO withError:error];
            if (error) {
                [UsageAnalytics trackUserSignupError:error usingMethod:@"facebook"];
                [self didFailToSignUpWithError:error];
            } else {
                if (user) {
                    [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"facebook"];
                    // Set the user's email and username to facebook email
                    [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser *) user block:nil];
                    [self didSignUpUser:user];
                } else {
                    [self didCancelSignUpUser];
                }
            }
        }];
    }
}

- (IBAction)didClickSignUpButton:(id)sender {
    
    NSString *password = self.passwordTextField.text ?: @"";
    NSString *email = self.emailAddressTextField.text ?: @"";

    if (![email isValidEmailAddress]) {
        [[[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] showWithButtonBlock:^(NSInteger buttonIndex) {
            [self.emailAddressTextField becomeFirstResponder];
        }];
    } else if ([password length] < 4) {
        [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Password must be at least 4 characters." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] showWithButtonBlock:^(NSInteger buttonIndex) {
            [self.passwordTextField becomeFirstResponder];
        }];
    } else if (![Reachability showAlertIfParseNotReachable]) {
        [self showStartSignUpProgress];
        PFUser *user = [PFUser user];
        user.username = email;
        user.email = email;
        user.password = password;
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [UsageAnalytics trackUserSignup:(ParentUser *) user usingMethod:@"parse"];
                [self didSignUpUser:user];
            } else {
                [UsageAnalytics trackUserSignupError:error usingMethod:@"parse"];
                [self didFailToSignUpWithError:error];
            }
        }];
    }
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

- (void)showStartSignUpProgress {
    [self showHUDWithMessage:@"Just a sec please..." andAnimation:YES];
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

- (void)showSignupSuccessAndRunBlock:(dispatch_block_t)block {
    [self showHUD:NO];
    UIImageView *animatedView = [self animatedImageView:@"success" frames:9];
    self.hud.customView = animatedView;
    [animatedView startAnimating];
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.completionBlock = block;
    [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

- (void)showSignupError:(NSError *)error withMessage:(NSString *)msg {
    UIImageView *animatedView = [self animatedImageView:@"error" frames:9];
    self.hud.customView = animatedView;
    self.hud.mode = MBProgressHUDModeCustomView;
    [animatedView startAnimating];
    NSLog(@"%@ caused by %@", msg, error);
    [self.hud hide:NO afterDelay:1.5];
}

+ (void)presentInController:(UIViewController *)vc andRunBlock:(PFBooleanResultBlock)block {
    SignUpViewController * signupVc = [vc.storyboard instantiateViewControllerWithIdentifier:@"signupViewController"];
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

-(void) didCancelSignUpUser {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (_block) _block(NO, nil);
}

// Sent to the delegate when a PFUser is signed up.
- (void) didSignUpUser:(PFUser *)user {
    [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    if (!user.ACL) {
        user.ACL = [PFACL ACLWithUser:user];
        [user saveEventually];
    }
    [self showSignupSuccessAndRunBlock:^{
        [[NSNotificationCenter defaultCenter]
                postNotificationName:kDDNotificationUserSignedUp object:user];
        [self dismissViewControllerAnimated:NO completion:nil];
        if (_block) _block(YES, nil);
    }];

}

- (void) didFailToSignUpWithError:(NSError *)error {
    [self showSignupError:error withMessage:@"Bummer!"];
    if (_block) _block(NO, error);
}


@end
