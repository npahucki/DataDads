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
}

- (IBAction)didEndEditingScreenName:(id)sender {
  [self.view endEditing:YES];
}

- (IBAction)didClickDoneButton:(id)sender {
  if(self.screenNameField.text && [self.screenNameField.text length] > 0) {
    PFUser * user = [PFUser currentUser];
    // TODO: Validate unique!
    [user setObject:self.screenNameField.text forKey:kDDUserScreenName];
    // TODO: Save syncronously
    [user saveEventually];
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}


@end
