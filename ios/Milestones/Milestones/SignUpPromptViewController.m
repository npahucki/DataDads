//
//  TipsSignUpPromptViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "SignUpPromptViewController.h"
#import "SignUpViewController.h"

@interface SignUpPromptViewController ()

@end

@implementation SignUpPromptViewController



- (void)viewDidLoad
{
  [super viewDidLoad];
  self.promptTextLabel.font = [UIFont fontForAppWithType:Light andSize:19.0];
  self.promptTextLabel.textColor = [UIColor appGreyTextColor];
  self.helloLabel.font = [UIFont fontForAppWithType:Bold andSize:35.0];
}

- (IBAction)didClickSignUpNow:(id)sender {
  SignUpViewController* signupController = [[SignUpViewController alloc] init];
  [self presentViewController:signupController animated:YES completion:nil];
}

@end
