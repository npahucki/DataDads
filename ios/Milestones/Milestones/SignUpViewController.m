//
//  SignupViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "SignUpViewController.h"

@interface SignUpViewController ()

@end

@implementation SignUpViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
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


@end
