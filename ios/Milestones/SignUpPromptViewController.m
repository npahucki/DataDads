//
//  TipsSignUpPromptViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SignUpPromptViewController.h"
#import "SignUpViewController.h"
#import "LoginViewController.h"

@interface SignUpPromptViewController ()

@end

@implementation SignUpPromptViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.promptTextLabel.font = [UIFont fontForAppWithType:Medium andSize:21.0];
    self.promptTextLabel.textColor = [UIColor blackColor];
    self.helloLabel.font = [UIFont fontForAppWithType:Bold andSize:18.0];
    
    self.signupNowButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.signupNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (IBAction)didClickSignUpNow:(id)sender {
    SignUpViewController *signupController = [[SignUpViewController alloc] init];
    signupController.showExternal = YES;
    [self presentViewController:signupController animated:YES completion:nil];
}

//- (IBAction)didClickLogin:(id)sender {
//    LoginViewController *loginController = [[LoginViewController alloc] init];
//    [self presentViewController:loginController animated:YES completion:nil];
//}

@end
