//
//  LoginViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()


@end

@implementation LoginViewController

-(void)awakeFromNib {
  self.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook | PFLogInFieldsTwitter | PFSignUpFieldsAdditional;
  self.facebookPermissions = @[ @"user_about_me", @"email" ];
  
}

-(id)initWithCoder:(NSCoder *)aDecoder {
  return [super initWithCoder:aDecoder];
  self.fields = PFLogInFieldsDefault |  PFLogInFieldsFacebook | PFLogInFieldsTwitter | PFSignUpFieldsAdditional;
}

- (void)viewDidLoad
{
  self.delegate = self;
 // self.view.backgroundColor = [UIColor colorWithPatternImage:
 //                              [UIImage imageNamed:@"myBackgroundImage.png"]];
  UILabel* label = [[UILabel alloc]init];
  label.text = @"Data Dads";
  [label sizeToFit];
  self.logInView.logo = label; // logo can be any UIView
  [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


/*!
 Sent to the delegate to determine whether the log in request should be submitted to the server.
 @param username the username the user tries to log in with.
 @param password the password the user tries to log in with.
 @result a boolean indicating whether the log in should proceed.
 */
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
  return YES;
}

/*! @name Responding to Actions */
/// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
  [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
}

/// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error logging in"
                                                  message:@"Please check the username and password you entered and try again, or if you don't have an account already, press the signup button."
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}




@end
