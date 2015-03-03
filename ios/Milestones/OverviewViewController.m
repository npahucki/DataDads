//
//  SettingsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <hipmob/HMService.h>
#import "OverviewViewController.h"
#import "SignUpOrLoginViewController.h"
#import "BabyInfoViewController.h"
#import "PFCloud+Cache.h"

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
    self.babyAvatar.alpha = 1.0;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.babyAvatar.layer setCornerRadius:self.babyAvatar.frame.size.width / 2];
    self.babyAvatar.layer.masksToBounds = YES;
    self.babyAvatar.layer.borderWidth = 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateLoginButtonTitle];
}

- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)logoutButtonPressed:(id)sender {

    if ([Reachability showAlertIfParseNotReachable]) return;

    if (![ParentUser currentUser].isLoggedIn) { // signed in if email present
        [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:nil];
    } else {
        ParentUser *user = [ParentUser currentUser];
        [UsageAnalytics trackUserSignout:ParentUser.currentUser];
        [[PFInstallation currentInstallation] setObject:[NSNull null] forKey:@"user"];
        [[PFInstallation currentInstallation] saveEventually];
        [PFUser logOut];
        [PFQuery clearAllCachedResults];
        [PFCloud clearAllCachedResults];
        [[PFFacebookUtils session] close];
        [[PFFacebookUtils session] closeAndClearTokenInformation];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationUserLoggedOut object:user];
        Baby.currentBaby = nil;
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)didClickChatButton:(id)sender {
    [[HMService sharedService] openChat:self withSetup:^(HMChatViewController *livechat) {
        livechat.navigationBar.tintColor = [UIColor appNormalColor];
        livechat.title = @"Support Session";
        livechat.chatView.maxInputLines = 4;
        livechat.chatView.sentMessageFont = [UIFont fontForAppWithType:Medium andSize:16];
        livechat.chatView.sentTextColor = [UIColor whiteColor];
        livechat.chatView.receivedMessageFont = [UIFont fontForAppWithType:Bold andSize:18];
        livechat.chatView.receivedTextColor = [UIColor appNormalColor];
        livechat.chatView.receivedTextColor = [UIColor appNormalColor];
        livechat.forcePortrait = YES;
        livechat.disableWebViewGestures = YES; // So we don't swipe back to the main screen.
        [livechat.chatView updateContext:@"Overview Controller"];

        ParentUser *user = [ParentUser currentUser];
        if (user.hasEmail) [livechat.chatView updateEmail:user.email];
        if (user.fullName) [livechat.chatView updateName:user.fullName];
        livechat.shouldUseSystemBrowser = NO;
    }];
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
    ParentUser *u = [ParentUser currentUser];
    if (u.isLoggedIn) {
        [self.logOutOrSignUpButton setTitle:[NSString stringWithFormat:@"log out %@", u.fullName ?: u.email ?: @""] forState:UIControlStateNormal];
    } else {
        [self.logOutOrSignUpButton setTitle:@"sign up now" forState:UIControlStateNormal];
    }
}


@end
