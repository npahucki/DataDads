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
  label.textColor = [UIColor appBlueColor];
  [label sizeToFit];
  self.signUpView.logo = label;
  //self.logInView.logo = [[UIView alloc]init];
  //[self.logInView.logo addSubview:label];
  //[self.logInView.logo addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcomeScreenBaby"]]];

  // Username
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
  self.signUpView.signUpButton.backgroundColor = [UIColor appBlueColor];
  self.signUpView.signUpButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  self.signUpView.signUpButton.titleLabel.textColor = [UIColor whiteColor];
  [self.signUpView.signUpButton setTitle:@"Sign Up" forState:UIControlStateNormal];
  self.signUpView.signUpButton.titleLabel.backgroundColor = [UIColor appBlueColor];
  self.signUpView.signUpButton.layer.cornerRadius = 8;
  
  
}


-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Make up for hidden email field.
  self.signUpView.signUpButton.center = CGPointMake(self.signUpView.signUpButton.center.x, self.signUpView.signUpButton.center.y - self.signUpView.emailField.frame.size.height);
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



  
  



@end