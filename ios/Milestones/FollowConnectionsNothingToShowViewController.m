//
//  FollowConnectionsNothingToShowViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/16/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionsNothingToShowViewController.h"
#import "SignUpViewController.h"

@interface FollowConnectionsNothingToShowViewController ()

@end

@implementation FollowConnectionsNothingToShowViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Override the UIAppearance settings
    self.promptTextLabel.font = [UIFont fontForAppWithType:Medium andSize:21.0];
    self.promptTextLabel.textColor = [UIColor blackColor];
    self.helloLabel.font = [UIFont fontForAppWithType:Bold andSize:18.0];
    self.signupButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateMode];
}


- (void)updateMode {
    [self.view.layer removeAllAnimations];
    self.signupNowArrowImageView.alpha = 1;
    self.addContactArrowImageView.alpha = 1;

    // Decide which message to show!
    if (![PFUser currentUser].email) {
        // They need to log in first!
        self.signupButton.hidden = NO;
        self.signupNowArrowImageView.hidden = NO;
        self.addContactArrowImageView.hidden = YES;
        self.promptTextLabel.text = [NSString stringWithFormat:@"Invite your friends and family to follow %@'s progress! To get started press the SIGN UP NOW button.", Baby.currentBaby.name];
        self.signupNowArrowImageViewBottomConstraint.constant = 36;
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:2.0 delay:0 usingSpringWithDamping:0.1 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signupNowArrowImageViewBottomConstraint.constant = 8;
            [self.view layoutIfNeeded];
        }                completion:NULL];
    } else {
        // Nothing to show
        self.signupButton.hidden = YES;
        self.signupNowArrowImageView.hidden = YES;
        self.addContactArrowImageView.hidden = NO;
        self.promptTextLabel.text = [NSString stringWithFormat:@"Invite your friends and family to follow %@'s progress! To get started press + button above.", Baby.currentBaby.name];
        // Animate the arrow
        self.addContactArrowImageViewTopConstraint.constant = 36;
        [self.view layoutIfNeeded];

        [UIView animateWithDuration:2.0 delay:0 usingSpringWithDamping:0.1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addContactArrowImageViewTopConstraint.constant = 8;
            [self.view layoutIfNeeded];
        }                completion:^(BOOL finished) {
            [UIView animateWithDuration:1.0 delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.addContactArrowImageView.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 self.addContactArrowImageView.hidden = YES;
                             }];

        }];
    }
}

- (IBAction)didClickSignUpNow:(id)sender {
    SignUpViewController *signupController = [[SignUpViewController alloc] init];
    signupController.showExternal = YES;
    [self presentViewController:signupController animated:YES completion:nil];
}


@end
