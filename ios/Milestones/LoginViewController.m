//
//  LoginViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "LoginViewController.h"
#import "SignUpViewController.h"

@interface LoginViewController ()


@end

@implementation LoginViewController

-(void)awakeFromNib {
  self.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook | /*PFLogInFieldsTwitter |*/ PFSignUpFieldsAdditional | PFLogInFieldsDismissButton;
  self.facebookPermissions = @[ @"user_about_me", @"email" ];
  
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kDDNotificationUserSignedUp object:nil];
}



- (void)viewDidLoad
{
  [super viewDidLoad];
  self.delegate = self;
  [self.logInView setBackgroundColor:[UIColor whiteColor]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignedUp:) name:kDDNotificationUserSignedUp object:nil];

  // Setup Signin Controller
  self.signUpController = [[SignUpViewController alloc] init];
  self.signUpController.delegate = self;
  


  
  // LOGO / Title
  UILabel* label = [[UILabel alloc]init];
  label.text = @"Login to Data Dads";
  label.font = [UIFont fontForAppWithType:Bold andSize:27];
  label.textColor = [UIColor appNormalColor];
  [label sizeToFit];
  self.logInView.logo = label;
  
  // Username
  [self.logInView.usernameField setKeyboardType:UIKeyboardTypeEmailAddress];
  self.logInView.usernameField.textColor = [UIColor appGreyTextColor];
  self.logInView.usernameField.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  self.logInView.usernameField.layer.borderWidth = 1;
  self.logInView.usernameField.layer.cornerRadius = 8;
  self.logInView.usernameField.backgroundColor = [UIColor whiteColor];
  self.logInView.usernameField.layer.shadowOpacity = 0.0;
  self.logInView.usernameField.placeholder = @"Email Address";
  
  // Pasword
  self.logInView.passwordField.textColor = [UIColor appGreyTextColor];
  self.logInView.passwordField.borderStyle = UITextBorderStyleRoundedRect;
  self.logInView.passwordField.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  self.logInView.passwordField.layer.borderWidth = 1;
  self.logInView.passwordField.layer.cornerRadius = 8;
  self.logInView.passwordField.backgroundColor = [UIColor whiteColor];
  self.logInView.passwordField.layer.shadowOpacity = 0.0;

  
  self.logInView.passwordForgottenButton.backgroundColor = [UIColor appNormalColor];
  
  // Loging button
  [self.logInView.logInButton setImage:nil forState:UIControlStateHighlighted];
  [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateHighlighted];
  [self.logInView.logInButton setBackgroundImage:nil forState:UIControlStateNormal];
  self.logInView.logInButton.backgroundColor = [UIColor appNormalColor];
  self.logInView.logInButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  self.logInView.logInButton.titleLabel.textColor = [UIColor whiteColor];
  [self.logInView.logInButton setTitle:@"Login" forState:UIControlStateNormal];
  self.logInView.logInButton.titleLabel.backgroundColor = [UIColor appNormalColor];
  self.logInView.logInButton.layer.cornerRadius = 8;
  

  // Or label
  self.logInView.externalLogInLabel.text = @"or";
  self.orSep = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orSep"]];
  [self.logInView addSubview:self.orSep];
  
  // Facebook button
  [self.logInView.facebookButton setImage:[UIImage imageNamed:@"facebookIcon"] forState:UIControlStateNormal];
  [self.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
  [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateHighlighted];
  [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateNormal];
  self.logInView.facebookButton.backgroundColor = [UIColor appNormalColor];
  self.logInView.facebookButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  [self.logInView.facebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.logInView.facebookButton setTitle:@" Login with Facebook" forState:UIControlStateNormal];
  self.logInView.facebookButton.titleLabel.backgroundColor = [UIColor appNormalColor];
  self.logInView.facebookButton.layer.cornerRadius = 8;

  // Signup Sep
  self.signupSep = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.logInView.frame.size.width,1)];
  self.signupSep.backgroundColor = [UIColor appGreyTextColor];
  self.signupSep.alpha = 0.5;
  [self.logInView addSubview:self.signupSep];
  self.logInView.signUpLabel.text = @"";
  
  
  
  // Signup button
  NSMutableAttributedString * attrTitle = [[NSMutableAttributedString alloc] initWithString:@"No account yet? Sign Up!"];
  [attrTitle addAttribute:NSForegroundColorAttributeName value:[UIColor appGreyTextColor] range:NSMakeRange(0,15)];
  [attrTitle addAttribute:NSForegroundColorAttributeName value:[UIColor appNormalColor] range:NSMakeRange(16,attrTitle.length - 16 )];
  [attrTitle addAttribute:NSFontAttributeName value:[UIFont fontForAppWithType:Bold andSize:13] range:NSMakeRange(0,attrTitle.length - 1)];
  [self.logInView.signUpButton setAttributedTitle:attrTitle forState:UIControlStateNormal];
  [self.logInView.signUpButton setBackgroundImage:nil forState:UIControlStateNormal];
  [self.logInView.signUpButton setBackgroundImage:nil forState:UIControlStateHighlighted];
  [self.logInView.signUpButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
  self.logInView.signUpButton.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  self.logInView.signUpButton.layer.borderWidth = 1.0;
  self.logInView.signUpButton.layer.cornerRadius = 8;
  self.logInView.signUpButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  self.logInView.signUpButton.titleLabel.layer.shadowOpacity = 0.0;

  // Forgot password button
  [self.logInView.passwordForgottenButton setBackgroundImage:[UIImage imageNamed:@"forgotPassword"] forState:UIControlStateNormal];
  [self.logInView.passwordForgottenButton setImage:nil forState:UIControlStateHighlighted];
  self.logInView.passwordForgottenButton.layer.cornerRadius = 8;
  
  
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.orSep.center = self.logInView.externalLogInLabel.center;
  self.logInView.facebookButton.center = CGPointMake(self.logInView.facebookButton.center.x, self.logInView.facebookButton.center.y + 15);
  self.logInView.logInButton.center = CGPointMake(self.logInView.logInButton.center.x, self.logInView.logInButton.center.y + 10);
  self.signupSep.center = self.logInView.signUpLabel.center;
  
  int logoY = (self.logInView.usernameField.frame.origin.y + self.logInView.logo.frame.size.height) / 2;
  self.logInView.logo.center = CGPointMake(self.logInView.logo.center.x,logoY - 150);
  
  self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.logInView];
  UIGravityBehavior* gravityBehavior =
  [[UIGravityBehavior alloc] initWithItems:@[ self.logInView.logo]];
  [self.animator addBehavior:gravityBehavior];
  
  UICollisionBehavior* collisionBehavior =
  [[UICollisionBehavior alloc] initWithItems:@[ self.logInView.logo]];
  collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;
  [collisionBehavior addBoundaryWithIdentifier:@"logoBoundry" fromPoint:CGPointMake(0, logoY) toPoint:CGPointMake(self.logInView.bounds.size.width, logoY)];
  [self.animator addBehavior:collisionBehavior];
  
  UIDynamicItemBehavior *elasticityBehavior =
  [[UIDynamicItemBehavior alloc] initWithItems:@[ self.logInView.logo]];
  elasticityBehavior.elasticity = 0.7f;
  [self.animator addBehavior:elasticityBehavior];
}

# pragma PFLoginViewController methods

/*!
 Sent to the delegate to determine whether the log in request should be submitted to the server.
 @param username the username the user tries to log in with.
 @param password the password the user tries to log in with.
 @result a boolean indicating whether the log in should proceed.
 */
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
  if([Reachability showAlertIfParseNotReachable]) {
    return NO;
  } else {
    [self showStartLoginProgress];
    return YES;
  }
}

/*! @name Responding to Actions */
/// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {

  // Make sure the current user is associated with the device.
  [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
  [[PFInstallation currentInstallation] saveEventually];
  user.ACL = [PFACL ACLWithUser:user];
  [user saveEventually];
  
  BOOL isLinkedToFacebook = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
  if(isLinkedToFacebook) {
    // We need to copy the email address and maybe some other attibutes here before we proceed.
    // We can do this in the background so as to let the user get started without additional delay.
    [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser*)user block:nil];
  }
  
  [self showLoginSuccessAndRunBlock:^{
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }];
}

/// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
  if(![PFFacebookUtils showAlertIfFacebookDisplayableError:error]) {
    NSString * msg = @"Please check the username and password you entered and try again, or if you don't have an account already, press the signup button.";
    [self showLoginErrorAndRunBlock:^{
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error logging in"
                                                      message:msg
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
    }];
  }
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
 [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) userSignedUp:(id) sender {
  [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Custom HUD Methods.

-(void) showHUD: (BOOL) animated {
  if(!self.hud) {
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
    self.hud.animationType = MBProgressHUDAnimationFade;
    self.hud.dimBackground = YES;
  }
  [self.hud show:animated];
}

-(void) showHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated {
  [self showHUD:animated];
  self.hud.labelText = msg;
}

-(void) showStartLoginProgress {
  [self showHUDWithMessage:@"Just a sec please..." andAnimation:YES];
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

-(void) showLoginSuccessAndRunBlock:(dispatch_block_t)block {
  [self showHUD:NO];
  UIImageView * animatedView = [self animatedImageView:@"success" frames:9];
  self.hud.customView = animatedView;
  [animatedView startAnimating];
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.completionBlock = block;
  [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

-(void) showLoginErrorAndRunBlock:(dispatch_block_t)block {
  UIImageView * animatedView = [self animatedImageView:@"error" frames:9];
  self.hud.customView = animatedView;
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.completionBlock = block;
  [animatedView startAnimating];
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




@end
