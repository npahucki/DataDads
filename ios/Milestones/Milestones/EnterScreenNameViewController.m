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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didEndEditingScreenName:(id)sender {
  [self.view endEditing:YES];
}

- (IBAction)didClickDoneButton:(id)sender {
  if(self.screenNameField.text && [self.screenNameField.text length] > 0) {
    PFUser * user = [PFUser currentUser];
    // TODO: Validate unique!
    [user setObject:self.screenNameField.text forKey:kDDUserScreenName];
    [user saveEventually];
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}


@end
