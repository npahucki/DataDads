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
  self.screenNameField.text = [PFUser.currentUser objectForKey:kDDUserScreenName];
  [self updateNextButtonState];
}

- (IBAction)didEndEditingScreenName:(id)sender {
  [self.view endEditing:YES];
  [self updateNextButtonState];
}

- (IBAction)didClickDoneButton:(id)sender {
  if(self.screenNameField.text && [self.screenNameField.text length] > 0) {
    PFUser * user = [PFUser currentUser];
    // TODO: Validate unique!
    [user setObject:self.screenNameField.text forKey:kDDUserScreenName];
    [user setObject: [NSNumber numberWithBool:self.maleButton.isSelected] forKey:kDDUserIsMale];
    [user saveInBackground];
    [self dismissViewControllerAnimated:NO completion:nil];
  }
}


- (IBAction)didClickMaleButton:(id)sender {
  self.maleButton.selected = YES;
  self.maleLabel.highlighted = YES;
  self.femaleButton.selected = NO;
  self.femaleLabel.highlighted = NO;
  [self updateNextButtonState];
}

- (IBAction)didClickFemaleButton:(id)sender {
  self.femaleButton.selected = YES;
  self.femaleLabel.highlighted = YES;
  self.maleButton.selected = NO;
  self.maleLabel.highlighted = NO;
  [self updateNextButtonState];
}

- (IBAction)didClickAnonymousButton:(id)sender {
  self.keepAnonymousButton.selected = !self.keepAnonymousButton.selected;
}

-(void) updateNextButtonState {
  self.nextButton.enabled = self.screenNameField.text.length > 1 && (self.maleButton.isSelected || self.femaleButton.isSelected);
}


@end
