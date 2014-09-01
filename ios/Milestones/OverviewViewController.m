//
//  SettingsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "OverviewViewController.h"
#import "SignUpViewController.h"
#import "BabyInfoViewController.h"

@implementation OverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(Baby.currentBaby.name, @"Expected a current baby would be set before setting invoked");
    self.babyNameLabel.font = [UIFont fontForAppWithType:Bold andSize:21.0];
    self.babyNameLabel.text = Baby.currentBaby.name;
    self.ageLabel.font = [UIFont fontForAppWithType:Medium andSize:18.0];
    self.ageLabel.text = [Baby.currentBaby ageAtDateFormattedAsNiceString:[NSDate date]];

    self.babyAvatar.file = Baby.currentBaby.avatarImage;
    [self.babyAvatar loadInBackground];

    // Handle any touches on the image or baby name to put into edit mode.
    [self.babyAvatar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditTap:)]];
    [self.babyNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditTap:)]];
    [self.ageLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditTap:)]];


    if (self.milestoneCount) {
        self.milestoneCountLabel = [[UILabel alloc] initWithFrame:self.babyAvatar.frame];
        self.milestoneCountLabel.numberOfLines = 0;
        self.milestoneCountLabel.textAlignment = NSTextAlignmentCenter;



        // Make the label show attributed text
        NSDictionary *numberAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:95.0], NSForegroundColorAttributeName : [UIColor appNormalColor]};
        NSDictionary *milestoneTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:18.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]};
        NSMutableAttributedString *milestoneString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%li\nmilestones noted", (long) self.milestoneCount]];
        NSUInteger numLen = [[@(self.milestoneCount) stringValue] length];
        [milestoneString setAttributes:numberAttributes range:NSMakeRange(0, numLen)];
        [milestoneString setAttributes:milestoneTextAttributes range:NSMakeRange(numLen + 1, [milestoneString length] - numLen - 1)];
        self.milestoneCountLabel.attributedText = milestoneString;

        [self.view addSubview:self.milestoneCountLabel];
        [UILabel animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionTransitionNone animations:^{
            self.milestoneCountLabel.alpha = 0.0;
        }                 completion:^(BOOL finished) {
            [self.milestoneCountLabel removeFromSuperview];
        }];
        [UIImageView animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionTransitionNone animations:^{
            self.babyAvatar.alpha = 1.0;
        }                     completion:^(BOOL finished) {
            self.babyAvatar.alpha = 1.0;
        }];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.babyAvatar.layer setCornerRadius:self.babyAvatar.frame.size.width / 2];
    self.babyAvatar.layer.masksToBounds = YES;
    self.babyAvatar.layer.borderWidth = 1;
    // This must be done after the final sizes for the image have been calculated, that's why it's not in viewDidLoad
    self.milestoneCountLabel.frame = CGRectInset(self.babyAvatar.frame, 10, 0); // Put label ontop of image

}

- (void)viewDidAppear:(BOOL)animated {
    [self updateLoginButtonTitle];
}

- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)logoutButtonPressed:(id)sender {

    if ([Reachability showAlertIfParseNotReachable]) return;

    if (!PFUser.currentUser.email) { // signed in if email present
        SignUpViewController *signupController = [[SignUpViewController alloc] init];
        signupController.showExternal = YES;
        [self presentViewController:signupController animated:YES completion:nil];
    } else {
        [UsageAnalytics trackUserSignout:ParentUser.currentUser];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationUserLoggedOut object:ParentUser.currentUser];
        [[PFInstallation currentInstallation] setObject:[NSNull null] forKey:@"user"];
        [[PFInstallation currentInstallation] saveEventually];
        [PFUser logOut];
        [PFQuery clearAllCachedResults];
        [[PFFacebookUtils session] close];
        [[PFFacebookUtils session] closeAndClearTokenInformation];
        Baby.currentBaby = nil;
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)handleEditTap:(id)sender {
    [self performSegueWithIdentifier:kDDSegueEnterBabyInfo sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDDSegueEnterBabyInfo]) {
        UINavigationController *navigationController = (UINavigationController *) segue.destinationViewController;
        id <ViewControllerWithBaby> controllerWithBaby = [[navigationController viewControllers] lastObject];
        [controllerWithBaby setBaby:Baby.currentBaby];
    }
}

- (void)updateLoginButtonTitle {
    if (!PFUser.currentUser.email.length) { // signed in if email present
        [self.logOutOrSignUpButton setTitle:@"sign up now" forState:UIControlStateNormal];
    } else {
        [self.logOutOrSignUpButton setTitle:@"log out now" forState:UIControlStateNormal];
    }
}


@end
