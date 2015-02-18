//
//  TipsSignUpPromptViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SignUpPromptViewController.h"
#import "SignUpOrLoginViewController.h"

@interface SignUpPromptViewController ()

@end

@implementation SignUpPromptViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.promptTextLabel.font = [UIFont fontForAppWithType:Medium andSize:26.0];
    self.promptTextLabel.textColor = [UIColor appGreyTextColor];
    self.promptTextLabel.text = [NSString stringWithFormat:self.promptTextLabel.text, [Baby currentBaby].name];

    self.auxPromptTextLabel.font = [UIFont fontForAppWithType:Medium andSize:16.0];
    self.auxPromptTextLabel.textColor = [UIColor appGreyTextColor];
    
    self.signupNowButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.signupNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];


    if (self.view.layer.animationKeys.count == 0) {
        self.arrowImageViewBottomConstraint.constant = 32;
        [self.view layoutIfNeeded];


        [UIView animateWithDuration:3.0 delay:0.0 usingSpringWithDamping:0.1 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.arrowImageViewBottomConstraint.constant = 8;
            [self.view layoutIfNeeded];
        }                completion:NULL];
    }

}

- (IBAction)didClickStartButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Sign Up" message:@"You need to signup to use the Tips feature."
                                                   delegate:nil
                                          cancelButtonTitle:@"Maybe Later"
                                          otherButtonTitles:@"Sign Up", nil];
    [alert showWithButtonBlock:^(NSInteger buttonIndex) {
        [UsageAnalytics trackSignupTrigger:@"promptForTipsFeature" withChoice:buttonIndex == 1];
        if (buttonIndex == 1) {
            [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:nil];
        }
    }];
}

@end
