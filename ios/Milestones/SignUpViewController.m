//
//  SignupViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "SignUpViewController.h"
#import <Parse/PF_MBProgressHUD.h>

@interface SignUpViewController ()

@end

@implementation SignUpViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.delegate = self;
  self.facebookPermissions = @[ @"user_about_me", @"email" ];
  
  // Hack because we can't seem to modify the behavior of the progress HUD and we want to show our own.
  // The Login View Controller will show the Hud
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"PF_MBProgressHUD"))
    {
      [subview removeFromSuperview];
      ((PF_MBProgressHUD *)subview).delegate = self;
    }
  }
  
  self.signUpView.backgroundColor = [UIColor whiteColor];
  self.fields = PFSignUpFieldsUsernameAndPassword
  | PFSignUpFieldsEmail
  | PFSignUpFieldsSignUpButton
  | PFSignUpFieldsDismissButton;
  
  // We use the username and email as the same to simplify
  self.signUpView.usernameField.placeholder = @"Email Address";
  [self.signUpView.emailField setHidden:YES];
  
  // Navigation Bar
  UINavigationBar *myBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.signUpView.frame.size.width, 44)];
  [myBar setBackgroundImage:[UIImage imageNamed:@"header"] forBarMetrics:UIBarMetricsDefault];
  [myBar pushNavigationItem:[[UINavigationItem alloc] init] animated:false];
  myBar.topItem.title = @"DataDads";
  // Insert BELOW the close button so it still works
  [self.signUpView insertSubview:myBar belowSubview:self.signUpView.dismissButton];
  
  
  // LOGO / Title
  UILabel* label = [[UILabel alloc]init];
  label.text = @"Sign Up!";
  label.font = [UIFont fontForAppWithType:Bold andSize:35];
  label.textColor = [UIColor appNormalColor];
  [label sizeToFit];
  self.signUpView.logo = label;

  // Username
  [self.signUpView.usernameField setKeyboardType:UIKeyboardTypeEmailAddress];
  self.signUpView.usernameField.textColor = [UIColor appGreyTextColor];
  self.signUpView.usernameField.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  self.signUpView.usernameField.layer.borderWidth = 1;
  self.signUpView.usernameField.layer.cornerRadius = 8;
  self.signUpView.usernameField.backgroundColor = [UIColor whiteColor];
  self.signUpView.usernameField.layer.shadowOpacity = 0.0;
  
  // Pasword
  self.signUpView.passwordField.textColor = [UIColor appGreyTextColor];
  self.signUpView.passwordField.borderStyle = UITextBorderStyleRoundedRect;
  self.signUpView.passwordField.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  self.signUpView.passwordField.layer.borderWidth = 1;
  self.signUpView.passwordField.layer.cornerRadius = 8;
  self.signUpView.passwordField.backgroundColor = [UIColor whiteColor];
  self.signUpView.passwordField.layer.shadowOpacity = 0.0;
  
  // Dismiss Button
  [self.signUpView.dismissButton setImage:[UIImage imageNamed:@"closeMenuButton"] forState:UIControlStateNormal];
  [self.signUpView.dismissButton setImage:[UIImage imageNamed:@"closeMenuButton_pressed"] forState:UIControlStateSelected];
  [self.signUpView.dismissButton setImage:[UIImage imageNamed:@"closeMenuButton_pressed"] forState:UIControlStateHighlighted];

  // Signup button
  [self.signUpView.signUpButton setImage:nil forState:UIControlStateHighlighted];
  [self.signUpView.signUpButton setBackgroundImage:nil forState:UIControlStateHighlighted];
  [self.signUpView.signUpButton setBackgroundImage:nil forState:UIControlStateNormal];
  self.signUpView.signUpButton.backgroundColor = [UIColor appNormalColor];
  self.signUpView.signUpButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  [self.signUpView.signUpButton setTitleColor:[UIColor appSelectedColor] forState:UIControlStateSelected];
  [self.signUpView.signUpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.signUpView.signUpButton setTitle:@"Sign Up" forState:UIControlStateNormal];
  self.signUpView.signUpButton.layer.cornerRadius = 8;
  
  if(self.showExternal) {

    self.orSep = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orSep"]];
    [self.signUpView addSubview:self.orSep];
    // Or label
    self.orLabel = [[UILabel alloc] initWithFrame:self.orSep.frame];
    self.orLabel.text= @"or";
    self.orLabel.textColor = [UIColor appGreyTextColor];
    self.orLabel.font = [UIFont fontForAppWithType:Medium andSize:13];
    self.orLabel.textAlignment = NSTextAlignmentCenter;
    [self.signUpView addSubview:self.orLabel];
    
    // Facebook button
    self.facebookButton = [[UIButton alloc] initWithFrame:self.signUpView.signUpButton.frame]; // position later
    [self.facebookButton setImage:[UIImage imageNamed:@"facebookIcon"] forState:UIControlStateNormal];
    self.facebookButton.backgroundColor = [UIColor appNormalColor];
    self.facebookButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
    [self.facebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.facebookButton setTitleColor:[UIColor appSelectedColor] forState:UIControlStateSelected];
    [self.facebookButton setTitle:@" Sign in with Facebook" forState:UIControlStateNormal];
    self.facebookButton.titleLabel.backgroundColor = [UIColor appNormalColor];
    self.facebookButton.layer.cornerRadius = 8;
    [self.facebookButton addTarget:self action:@selector(didClickFacebookButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.signUpView addSubview:self.facebookButton];
  }
}


-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Make up for hidden email field.
  self.signUpView.signUpButton.center = CGPointMake(self.signUpView.signUpButton.center.x, self.signUpView.signUpButton.center.y - self.signUpView.emailField.frame.size.height);

  self.orSep.center = CGPointMake(self.signUpView.signUpButton.center.x, self.signUpView.signUpButton.center.y + self.signUpView.emailField.frame.size.height + 8);
  self.orLabel.frame = self.orSep.frame;
  self.facebookButton.frame = self.signUpView.signUpButton.frame;
  self.facebookButton.center = CGPointMake(self.orSep.center.x, self.orSep.center.y + self.orSep.frame.size.height + 24);

}

-(void) didClickFacebookButton:(id) sender {
  [self showStartSignUpProgress];
  [PFFacebookUtils logInWithPermissions:self.facebookPermissions block:^(PFUser *user, NSError *error) {
    if (error) {
      [self signUpViewController:self didFailToSignUpWithError:error];
    } else {
      if(user) {
        // Set the user's email and username to facebook email
        [self populateCurrentUserDetailsFromFacebook:user];
      } // else use canceled
    }
  }];
}

-(void) populateCurrentUserDetailsFromFacebook: (PFUser *) user {
  [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    if (!error) {
      NSString *facebookEMail = result[@"email"];
      if (facebookEMail.length) {
        user.email = facebookEMail;
        user.username = facebookEMail;
      }
      [user saveEventually];
      [self signUpViewController:self didSignUpUser:user];
    } else {
      [self signUpViewController:self didFailToSignUpWithError:error];
    }
  }];
}


// Copy username to email
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  if (textField == self.signUpView.usernameField) {
    textField.text = [textField.text lowercaseString];
    self.signUpView.emailField.text = textField.text;
  }
  return YES;
}

- (void)hudWasHidden:(PF_MBProgressHUD *)hud {
  // This is to work around where the HUD is not closed when certain error messages are shown.
  if(self.hud.completionBlock == nil) // We are not already in the process of closing the dialog 
    self.hud.hidden = YES;
}

#pragma mark Custom HUD Methods.

-(void) showHUD: (BOOL) animated {
  if(!self.hud) {
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
    self.hud.animationType = MBProgressHUDAnimationFade;
    self.hud.dimBackground = NO;
    self.hud.completionBlock = nil;
  }
  [self.hud show:animated];
  self.hud.hidden = NO;
}

-(void) showHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated {
  [self showHUD:animated];
  self.hud.labelText = msg;
}

-(void) showStartSignUpProgress {
  [self showHUDWithMessage:@"Just a sec please..." andAnimation:YES];
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

-(void) showSignupSuccessAndRunBlock:(dispatch_block_t)block {
  [self showHUD:NO];
  UIImageView * animatedView = [self animatedImageView:@"success" frames:9];
  self.hud.customView = animatedView;
  [animatedView startAnimating];
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.completionBlock = block;
  [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

-(void) showSignupError:(NSError*) error withMessage:(NSString*) msg {
  UIImageView * animatedView = [self animatedImageView:@"error" frames:9];
  self.hud.customView = animatedView;
  self.hud.mode = MBProgressHUDModeCustomView;
  [animatedView startAnimating];
  NSLog(@"%@ caused by %@", msg, error);
  [self.hud hide:NO afterDelay:1.5]; // when hidden will dismiss the dialog.
}

-(UIImageView*) animatedImageView:(NSString*) imageName frames:(int) count {
  NSMutableArray * images = [[NSMutableArray alloc] initWithCapacity:count];
  for(int i=0; i<count; i++) {
    [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@-%d.png",imageName, i]]];
  }
  UIImageView* view = [[UIImageView alloc] initWithImage:images[count - 1]];
  view.animationImages = images;
  view.animationDuration = .75;
  view.animationRepeatCount = 1;
  return view;
  
}

# pragma PFSignUpViewControllerDelegate methods
// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
  [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
  [[PFInstallation currentInstallation] saveEventually];
  user.ACL = [PFACL ACLWithUser:user];
  [user saveEventually];
  
  [self showSignupSuccessAndRunBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kDDNotificationUserSignedUp object:self userInfo:[NSDictionary dictionaryWithObject:user forKey:@""]];
    [self dismissViewControllerAnimated:NO completion:nil];
  }];
  
}

- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
  if([Reachability showAlertIfParseNotReachable]) {
    return NO;
  } else {
    [self showStartSignUpProgress];
    return YES;
  }
}

/// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
  [self showSignupError:error withMessage:@"Bummer!"];
}



@end
