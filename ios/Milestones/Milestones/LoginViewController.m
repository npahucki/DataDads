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
  
  BOOL isLinkedToTwitter = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
  BOOL isLinkedToFacebook = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
  
  if(isLinkedToFacebook) {
    // We need to copy the email address and maybe some other attibutes here before we proceed.
    // We can do this in the background so as to let the user get started without additional delay.
    [self populateCurrentUserDetailsFromFacebook:user];
  } else if(isLinkedToTwitter) {
    [self populateCurrentUserDetailsFromTwitter:user];
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
  
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

-(void) populateCurrentUserDetailsFromFacebook: (PFUser *) user {
  [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    if (!error) {
      NSString *facebookEMail = result[@"email"];
      if (facebookEMail && [facebookEMail length] != 0) {
        // TODO: Just use first name and last initial
        [user setObject:facebookEMail forKey:kDDUserEmail];
      }
      [user saveEventually];
    } else {
      // TODO: more elegant logging
      NSLog(@"Facebook error while trying to fecth data about me to populate user: %@", error);
      
    }
  }];
}

-(void) populateCurrentUserDetailsFromTwitter: (PFUser *) user {
  // TODO:
  [self performSegueWithIdentifier:kDDSegueEnterScreenName sender:self];
}


@end
