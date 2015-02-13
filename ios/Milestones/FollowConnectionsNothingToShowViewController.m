//
//  FollowConnectionsNothingToShowViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/16/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionsNothingToShowViewController.h"


@implementation FollowConnectionsNothingToShowViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Override the UIAppearance settings
    self.promptTextLabel.font = [UIFont fontForAppWithType:Medium andSize:26.0];
    self.promptTextLabel.textColor = [UIColor appGreyTextColor];
    self.promptTextLabel.text = [NSString stringWithFormat:self.promptTextLabel.text, [Baby currentBaby].name];
    self.startButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
    [self.mainFollowController didClickInviteButton:sender];
}


@end
