//
//  SettingPanelViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SettingPanelViewController.h"
#import "WebViewerViewController.h"
#include <sys/sysctl.h>

@interface SettingPanelViewController ()

@end

@implementation SettingPanelViewController {
    BOOL _isLiveChatAvailable;
    HMChatOperatorAvailabilityCheck *_check;
    NSAttributedString *_earlyReaderText;
}

+ (void)initialize {
    [super initialize];
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], [SettingPanelViewController class], nil].font = [UIFont fontForAppWithType:Book andSize:17.0];
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], [SettingPanelViewController class], nil].textColor = [UIColor appHeaderNormalTextColor];
    // NOTE: This is deprecated with NO working replacement!!!!
    [UIButton appearanceWhenContainedIn:[UITableViewCell class], [SettingPanelViewController class], nil].font = [UIFont fontForAppWithType:Book andSize:19.0];
    [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].font = [UIFont fontForAppWithType:Bold andSize:18.0];
    [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].textColor = [UIColor appHeaderActiveTextColor];
    [UIView appearanceWhenContainedIn:[UITableViewHeaderFooterView class], [SettingPanelViewController class], nil].backgroundColor = [UIColor appHeaderBackgroundActiveColor];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.useMetricSwitch.on = ParentUser.currentUser.usesMetric;
    self.showHiddenTipsSwitch.on = ParentUser.currentUser.showHiddenTips;
    self.showIgnoredMilestonesSwitch.on = ParentUser.currentUser.showIgnoredMilestones;
    self.showPostponedMilestonesSwitch.on = ParentUser.currentUser.showPostponedMilestones;
    self.showMilestoneStatisticsSwitch.on = ParentUser.currentUser.showMilestoneStats;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSMutableParagraphStyle *center = [[NSMutableParagraphStyle alloc] init];
    center.alignment = NSTextAlignmentCenter;
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:@"Early Reader\n" attributes:@{
            NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:18.0],
            NSForegroundColorAttributeName : UIColorFromRGB(0xf0045a),
            NSParagraphStyleAttributeName : center

    }];
    NSAttributedString *descriptionString = [[NSAttributedString alloc] initWithString:@"Use the Doman method to teach your young baby how to read!\n" attributes:@{
            NSFontAttributeName : [UIFont fontForAppWithType:Book andSize:16.0],
            NSForegroundColorAttributeName : [UIColor appGreyTextColor],
            NSParagraphStyleAttributeName : center

    }];
    NSAttributedString *detailsString = [[NSAttributedString alloc] initWithString:@"For babies 6 months to 4 years old." attributes:@{
            NSFontAttributeName : [UIFont fontForAppWithType:Book andSize:10.0],
            NSForegroundColorAttributeName : [UIColor appGreyTextColor],
            NSParagraphStyleAttributeName : center
    }];
    NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [fullString appendAttributedString:descriptionString];
    [fullString appendAttributedString:detailsString];
    self.earlyReaderButton.titleLabel.numberOfLines = 0;
    [self.earlyReaderButton setAttributedTitle:fullString forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startLiveChatAvailabilityCheck];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    ParentUser.currentUser.usesMetric = self.useMetricSwitch.on;
    ParentUser.currentUser.showHiddenTips = self.showHiddenTipsSwitch.on;
    ParentUser.currentUser.showIgnoredMilestones = self.showIgnoredMilestonesSwitch.on;
    ParentUser.currentUser.showPostponedMilestones = self.showPostponedMilestonesSwitch.on;
    ParentUser.currentUser.showMilestoneStats = self.showMilestoneStatisticsSwitch.on;
    if (ParentUser.currentUser.isDirty) {
        [ParentUser.currentUser saveEventually:^(BOOL succeeded, NSError *error) {
            if (succeeded) [ParentUser.currentUser fetchInBackgroundWithBlock:nil];
        }];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationNeedDataRefreshNotification object:nil];
}

- (IBAction)didClickBackButton:(id)sender {
    [((SlideOverViewController *) self.navigationController.parentViewController) setSlideOverToHiddenPosition:YES];
}

- (IBAction)didClickGetSupport:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLSupport];
    vc.navigationItem.title = @"Support and FAQ";
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)didClickReadPrivacyPolicy:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLPrivacyPolicy];
    vc.navigationItem.title = @"Privacy Policy";
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)didClickEarlyReader:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/us/app/infant-iq-early-reader-teach/id946204982?mt=8"]];
    [UsageAnalytics trackClickedToViewOtherAppInAppStore:@"Early Reader"];
}


- (IBAction)didClickReadTermsAndConditions:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLTermsAndConditions];
    vc.navigationItem.title = @"Terms and Conditions";
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)didClickTellAFriend:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:?subject=Track your baby's first times too!&body=Hey,\nI found a new app for tracking %@'s first times. I'm really enjoying using it! You can get it here: %@.\n\n%@",
                                                 Baby.currentBaby.name,
                                                 @"https://itunes.apple.com/us/app/dataparenting-baby-milestones/id905124835?mt=8",
                                                 [ParentUser currentUser].fullName ?: @""];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    [UsageAnalytics trackToldFriend];
}

- (IBAction)didClickContactSupport:(id)sender {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *sDeviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *email = [NSString stringWithFormat:@"mailto:support@dataparenting.com?subject=[SUPPORT REQUEST]:%@&body=\n\n\n-------\nVersion:%@\nBuild:%@\nUserId:%@\nDevice:%@\n  System:%@ %@\n-------\n",
                                                 infoDictionary[(NSString *) kCFBundleNameKey],
                                                 infoDictionary[@"CFBundleShortVersionString"],
                                                 infoDictionary[(NSString *) kCFBundleVersionKey],
                                                 [ParentUser currentUser].objectId,
                                                 sDeviceModel,
                                                 [[UIDevice currentDevice] systemName],
                                                 [[UIDevice currentDevice] systemVersion]];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)didClickViewTutorial:(id)sender {
    [UsageAnalytics trackTutorialManuallyTaken];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"liveChat"] && !_isLiveChatAvailable) {
        [[[UIAlertView alloc] initWithTitle:@"Leave a Message?"
                                    message:@"We must be busy shushing our little ones and can't chat right now. We'll get back to you soon though!"
                                   delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil]
                showWithButtonBlock:^(NSInteger buttonIndex) {
                    if (buttonIndex == 1) {
                        [self didClickContactSupport:sender];
                    } else {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
        return NO;
    }
    return YES;
}

- (void)startLiveChatAvailabilityCheck {
    self.liveChatButton.enabled = _isLiveChatAvailable = NO;
    self.liveChatStatus.image = [UIImage imageNamed:@"hipmob-operator-connecting.png"];
    NSString *hipMobAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.HipMobAppId"];
    _check = [[HMChatOperatorAvailabilityCheck alloc] initWithAppID:hipMobAppId andNotify:self];
}

- (void)operatorCheck:(id)operatorCheck isOperatorAvailable:(NSString *)app {
    _check = nil;
    self.liveChatButton.enabled = _isLiveChatAvailable = YES;
    self.liveChatStatus.image = [UIImage imageNamed:@"hipmob-operator-available.png"];
}

- (void)operatorCheck:(id)operatorCheck isOperatorOffline:(NSString *)app {
    _check = nil;
    _isLiveChatAvailable = NO;
    self.liveChatButton.enabled = YES;
    self.liveChatStatus.image = [UIImage imageNamed:@"hipmob-operator-offline.png"];
}



@end
