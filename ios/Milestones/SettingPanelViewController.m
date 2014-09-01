//
//  SettingPanelViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SettingPanelViewController.h"
#import "WebViewerViewController.h"

@interface SettingPanelViewController ()

@end

@implementation SettingPanelViewController

+ (void)initialize {
    [super initialize];
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], [SettingPanelViewController class], nil].font = [UIFont fontForAppWithType:Medium andSize:14.0];
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], [SettingPanelViewController class], nil].textColor = [UIColor appInputGreyTextColor];
    [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].font = [UIFont fontForAppWithType:Bold andSize:16.0];
    [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].textColor = [UIColor appHeaderActiveTextColor];
    [UIView appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].backgroundColor = [UIColor appHeaderBackgroundActiveColor];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.useMetricSwitch.on = ParentUser.currentUser.usesMetric;
    self.automaticallyShareOnFacebookSwitch.on = ParentUser.currentUser.autoPublishToFacebook;
    self.showHiddenTipsSwitch.on = ParentUser.currentUser.showHiddenTips;
    self.showIgnoredMilestonesSwitch.on = ParentUser.currentUser.showIgnoredMilestones;
    self.showPostponedMilestonesSwitch.on = ParentUser.currentUser.showPostponedMilestones;

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    ParentUser.currentUser.usesMetric = self.useMetricSwitch.on;
    ParentUser.currentUser.autoPublishToFacebook = self.automaticallyShareOnFacebookSwitch.on;
    ParentUser.currentUser.showHiddenTips = self.showHiddenTipsSwitch.on;
    ParentUser.currentUser.showIgnoredMilestones = self.showIgnoredMilestonesSwitch.on;
    ParentUser.currentUser.showPostponedMilestones = self.showPostponedMilestonesSwitch.on;
    if (ParentUser.currentUser.isDirty) {
        [ParentUser.currentUser saveEventually:^(BOOL succeeded, NSError *error) {
            if (succeeded) [ParentUser.currentUser refreshInBackgroundWithBlock:nil];
        }];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationNeedDataRefreshNotification object:nil];
}

- (IBAction)didChangeFacebookSwitch:(id)sender {
    if (self.automaticallyShareOnFacebookSwitch.on) {
        [PFFacebookUtils ensureHasPublishPermissions:ParentUser.currentUser block:^(BOOL succeeded, NSError *error) {
            if (error) {
                [PFFacebookUtils showAlertIfFacebookDisplayableError:error];
                [self.automaticallyShareOnFacebookSwitch setOn:NO animated:YES];
            } else if (!succeeded) {
                // User did not link or did not give permissions.
                [self.automaticallyShareOnFacebookSwitch setOn:NO animated:YES];
            }
        }];
    }
}

- (IBAction)didClickReadPrivacyPolicy:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLPrivacyPolicy];
    [self presentViewController:vc animated:YES completion:NULL];
}

- (IBAction)didClickReadTermsAndConditions:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLTermsAndConditions];
    [self presentViewController:vc animated:YES completion:NULL];
}

- (IBAction)didClickContactSuport:(id)sender {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *email = [NSString stringWithFormat:@"mailto:support@dataparenting.com?subject=[SUPPORT REQUEST]:%@&body=\n\n\n-------\nVersion:%@\nBuild:%@\nUserId:%@\nDevice:%@\n  System:%@ %@\n-------\n",
                                                 infoDictionary[(NSString *) kCFBundleNameKey],
                                                 infoDictionary[(NSString *) @"CFBundleShortVersionString"],
                                                 infoDictionary[(NSString *) kCFBundleVersionKey],
                                                 [ParentUser currentUser].objectId,
                                                 [[UIDevice currentDevice] model],
                                                 [[UIDevice currentDevice] systemName],
                                                 [[UIDevice currentDevice] systemVersion]];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)didClickViewTutorial:(id)sender {
}

@end
