//
//  EnterScreenNameViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <CMPopTipView/CMPopTipView.h>
#import "EnterScreenNameViewController.h"
#import "WebViewerViewController.h"
#import "CMPopTipView+WithStaticInitializer.h"


@implementation EnterScreenNameViewController {
    CMPopTipView *_tutorialBubbleView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.doneButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:17]} forState:UIControlStateNormal];
    self.maleLabel.textColor = self.femaleLabel.textColor = [UIColor appInputGreyTextColor];
    self.maleLabel.highlightedTextColor = self.femaleLabel.highlightedTextColor = [UIColor appNormalColor];
    self.maleLabel.font = self.femaleLabel.font = [UIFont fontForAppWithType:Bold andSize:17.0];


    self.acceptTACButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:12.5];
    self.supportScienceButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:12.5];
    self.iAmLabel.font = [UIFont fontForAppWithType:Light andSize:22];
    
    [[UIDevice currentDevice] name];
    NSNumber *gender = [ParentUser.currentUser objectForKey:@"isMale"];
    if (gender && gender.boolValue) {
        [self didClickMaleButton:self];
    } else if (gender && !gender.boolValue) {
        [self didClickFemaleButton:self];
    }

    // Needed to dimiss the keyboard once a user clicks outside the text boxes
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:viewTap];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:NO];
    [self updateNextButtonState];
}

- (IBAction)didClickAgreeTACButton:(id)sender {
    self.acceptTACButton.selected = !self.acceptTACButton.selected;
    [self updateNextButtonState];
}

- (IBAction)didClickSupportScienceButton:(id)sender {
    self.supportScienceButton.selected = !self.supportScienceButton.selected;
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
    _tutorialBubbleView = nil;
}

- (IBAction)didClickSupportScienceInfoButton:(id)sender {
    if (_tutorialBubbleView) {
        [self dismissTutorialBubbleViewInfo];
    } else {
        _tutorialBubbleView = [CMPopTipView instanceWithApplicationLookAndFeelAndMessage:
                @"Your child's milestone data will be anonymously"
                        " aggregated for select scientists. If you don't agree, your child's upcoming milestone may be less accurate."];
        _tutorialBubbleView.delegate = self;
        _tutorialBubbleView.textFont = [UIFont fontForAppWithType:Medium andSize:14];
        _tutorialBubbleView.maxWidth = self.view.frame.size.width - 20;
        [_tutorialBubbleView presentPointingAtView:sender inView:self.view animated:YES];
    }
}

- (void)dismissTutorialBubbleViewInfo {
    [_tutorialBubbleView dismissAnimated:YES];
    _tutorialBubbleView = nil;
}

- (IBAction)didClickDoneButton:(id)sender {

    if ([Reachability showAlertIfParseNotReachable]) return;

    ParentUser *parent = [ParentUser currentUser];
    if (parent.username.length) {
        // Account already exists (logged in before, perhaps with facebook).
        [self saveUserPreferences:parent];
    } else {
        [self showInProgressHUDWithMessage:@"Registering..." andAnimation:YES andDimmedBackground:YES withCancel:NO];
        [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
            if (error) {
                [self showErrorThenRunBlock:error withMessage:@"Unable to register. Please check your internet connection and try again." andBlock:nil];
            } else {
                [self saveUserPreferences:(ParentUser *) user];
                [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
                [[PFInstallation currentInstallation] saveEventually];
            }
        }];
    }
}

- (void)saveUserPreferences:(ParentUser *)user {
    user.ACL = [PFACL ACLWithUser:user];
    if (!user.fullName) user.fullName = [ParentUser nameFromCurrentDevice];
    user.isMale = self.maleButton.isSelected;
    user.supportScience = self.supportScienceButton.isSelected;

    [self showInProgressHUDWithMessage:@"Saving your preferences" andAnimation:YES andDimmedBackground:YES withCancel:NO];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:@"Unable to save preferences" andBlock:nil];
        } else {
            self.baby.parentUser = user;
            [self saveBaby];
        }
    }];
}

- (IBAction)didClickMaleButton:(id)sender {
    self.maleButton.selected = YES;
    self.maleLabel.highlighted = YES;
    self.femaleButton.selected = NO;
    self.femaleLabel.highlighted = NO;
    [self.view endEditing:YES];
    [self updateNextButtonState];
}

- (IBAction)didClickFemaleButton:(id)sender {
    self.femaleButton.selected = YES;
    self.femaleLabel.highlighted = YES;
    self.maleButton.selected = NO;
    self.maleLabel.highlighted = NO;
    [self.view endEditing:YES];
    [self updateNextButtonState];
}

- (void)updateNextButtonState {
    self.doneButton.enabled = (self.maleButton.isSelected || self.femaleButton.isSelected) && self.acceptTACButton.selected;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDDSegueShowWebView]) {
        WebViewerViewController *webView = (WebViewerViewController *) segue.destinationViewController;
        webView.url = [NSURL URLWithString:kDDURLTermsAndConditions];
        webView.showCloseButton = YES;
    }
}

- (void)saveBaby {
    BOOL isNewBaby = self.baby.objectId == nil;
    [self saveBabyAvatar:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:@"Could not save baby's photo" andBlock:nil];
        } else {
            [self saveBabyObject:^(BOOL succeeded2, NSError *error2) {
                if (error2) {
                    [self showErrorThenRunBlock:error2 withMessage:@"Could not save baby's information" andBlock:nil];
                } else {
                    if (isNewBaby) {
                        [self saveBirthdayMilestone];
                        [UsageAnalytics trackCreateBaby:self.baby];
                    }
                    [self showSuccessThenRunBlock:^{
                        [self dismiss];
                    }];
                }
            }];
        }
    }];
}

- (void)saveBabyObject:(PFBooleanResultBlock)block {
    if (self.baby.isDirty) {
        self.baby.ACL = [PFACL ACLWithUser:self.baby.parentUser];
        Baby.currentBaby = nil; // Clear the current baby, will get set on the MainViewController
        [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Saving %@'s info", self.baby.name] andAnimation:YES andDimmedBackground:YES withCancel:NO];
        [self.baby saveInBackgroundWithBlock:block];
    } else {
        block(NO, nil);
    }
}

- (void)saveBabyAvatar:(PFBooleanResultBlock)block {
    if (self.baby.avatarImage.isDirty) {
        [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Uploading %@'s photo", self.baby.name] andAnimation:YES andDimmedBackground:YES withCancel:NO];
        [self.baby.avatarImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [self showErrorThenRunBlock:error withMessage:@"Could not upload photo." andBlock:^{
                    block(NO, error);
                }];
            } else {
                block(YES, nil);
            }
        }                                  progressBlock:^(int percentDone) {
        }];
    } else {
        block(NO, nil);
    }
}

- (void)saveBirthdayMilestone {
    __block MilestoneAchievement *achievement = [MilestoneAchievement object];
    achievement.baby = self.baby;
    achievement.customTitle = @"${He}'s born and is beautiful!";
    achievement.isPostponed = NO;
    achievement.isSkipped = NO;
    achievement.completionDate = self.baby.birthDate;

    [achievement saveEventually:^(BOOL succeeded, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:achievement];
    }];
}

- (void)dismiss {
    if (self.presentingViewController.presentingViewController) {
        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
