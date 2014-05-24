//
//  EnterScreenNameViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "EnterScreenNameViewController.h"

@interface EnterScreenNameViewController ()

@end

@implementation EnterScreenNameViewController



- (void)viewDidLoad
{
  [super viewDidLoad];
  self.keepAnonymousButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13.0];
  [self.keepAnonymousButton setTitleColor:[UIColor appNormalColor] forState:UIControlStateSelected];
  self.acceptTACLabelButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13.0];

  
  // TODO: See if we can load a default screen name based on the hostname
  // The below API
  
//  NSArray *hostNameArray = [[NSHost currentHost] names];
//  NSLog(@”Host Names : %@”, hostNameArray);
//  NSString *userNameString = [hostNameArray objectAtIndex:0];
//  NSLog(@”UserName : %@”, userNameString);
  
  //self.screenNameField.text = [PFUser.currentUser objectForKey:kDDUserScreenName];
  //[self updateNextButtonState];
  
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
  [self updateNextButtonState];
}


- (IBAction)didEndEditingScreenName:(id)sender {
  [self.view endEditing:YES];
  [self updateNextButtonState];
}

- (IBAction)didClickAgreeTACButton:(id)sender {
  self.acceptTACButton.selected = !self.acceptTACButton.selected;
  [self updateNextButtonState];
}

- (IBAction)didClickKeepAnonymousButton:(id)sender {
  self.keepAnonymousButton.selected = !self.keepAnonymousButton.selected;
}

- (IBAction)didClickDoneButton:(id)sender {

  [self showInProgressHUDWithMessage:@"Creating an account for you" andAnimation:YES andDimmedBackground:YES];
  [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
    if (error) {
      [self showErrorThenRunBlock:error withMessage:@"Unable create your account" andBlock:nil];
    } else {
      [user setObject:self.screenNameField.text forKey:kDDUserScreenName];
      [user setObject: [NSNumber numberWithBool:self.maleButton.isSelected] forKey:kDDUserIsMale];
      [user setObject: [NSNumber numberWithBool:self.keepAnonymousButton.selected] forKey:kDDUserKeepAnonymous];

      [self showInProgressHUDWithMessage:@"Saving your preferences" andAnimation:YES andDimmedBackground:YES];
      [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error) {
          [self showErrorThenRunBlock:error withMessage:@"Unable to save preferences" andBlock:^{
          }];
        } else {
          self.baby.parentUserId = user.objectId;
          [self saveBaby];
        }
      }];
    }
  }];
}

- (IBAction)didClickMaleButton:(id)sender {
  self.maleButton.selected = YES;
  self.maleLabel.highlighted = YES;
  self.femaleButton.selected = NO;
  self.femaleLabel.highlighted = NO;
  [self.view endEditing:YES];
}

- (IBAction)didClickFemaleButton:(id)sender {
  self.femaleButton.selected = YES;
  self.femaleLabel.highlighted = YES;
  self.maleButton.selected = NO;
  self.maleLabel.highlighted = NO;
  [self.view endEditing:YES];
}

-(void) updateNextButtonState {
  self.doneButton.enabled = self.screenNameField.text.length > 1 && (self.maleButton.isSelected || self.femaleButton.isSelected) && self.acceptTACButton.selected;
}

// TODO: Move save baby logic somewhere else that can be shared.
-(void) saveBaby {

  [self saveObject:self.baby withTitle:[NSString stringWithFormat:@"Saving %@'s info", self.baby.name] andFailureMessage:@"Could not save baby's information" andBlock:^(NSError *error) {
    if(!error) {
      Baby.currentBaby = self.baby;
 
      if(self.baby.avatarImage) {
        [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Uploading %@'s photo", self.baby.name] andAnimation:YES andDimmedBackground:YES];
        [self.baby.avatarImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
          if(error) {
            [self showErrorThenRunBlock:error withMessage:@"Could not upload photo." andBlock:nil];
          } else {
            [self saveBirthdayMilestone];
          }
        } progressBlock:^(int percentDone) {
        }];
      } else {
        [self saveBirthdayMilestone];
      }
    }
  }];
}

-(void) saveBirthdayMilestone {
  // TODO:
  [self dismiss];
}

-(void) dismiss {
  [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
