//
//  EnterScreenNameViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "EnterScreenNameViewController.h"
#import "WebViewerViewController.h"


@implementation EnterScreenNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.doneButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:17]} forState:UIControlStateNormal];
    self.maleLabel.textColor = self.femaleLabel.textColor = [UIColor appInputGreyTextColor];
    self.maleLabel.highlightedTextColor = self.femaleLabel.highlightedTextColor = [UIColor appNormalColor];
    self.maleLabel.font = self.femaleLabel.font = [UIFont fontForAppWithType:Bold andSize:17.0];

    
    self.acceptTACLabelButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:13.0];
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


- (IBAction)didChangeScreenName:(id)sender {
//  [self.view endEditing:YES];
    [self updateNextButtonState];
}

- (IBAction)didClickAgreeTACButton:(id)sender {
    self.acceptTACButton.selected = !self.acceptTACButton.selected;
    [self updateNextButtonState];
}

- (IBAction)didClickDoneButton:(id)sender {

    if ([Reachability showAlertIfParseNotReachable]) return;

    ParentUser *parent = [ParentUser currentUser];
    if (parent.username.length) {
        // Account already exists (logged in before, perhaps with facebook).
        [self saveUserPreferences:parent];
    } else {
        [self showInProgressHUDWithMessage:@"Registering..." andAnimation:YES andDimmedBackground:YES];
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
    if(!user.screenName) user.screenName = [self nameFromDeviceName];
    user.isMale = self.maleButton.isSelected;

    [self showInProgressHUDWithMessage:@"Saving your preferences" andAnimation:YES andDimmedBackground:YES];
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
        webView.url = [NSURL URLWithString:kTermsAndConditionUrl];
    }
}

- (void)saveBaby {
    BOOL isNewBaby = self.baby.objectId == nil;
    [self saveBabyAvatar:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:@"Could not save baby's photo" andBlock:nil];
        } else {
            [self saveBabyObject:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [self showErrorThenRunBlock:error withMessage:@"Could not save baby's information" andBlock:nil];
                } else {
                    if (isNewBaby) [self saveBirthdayMilestone];
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
        [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Saving %@'s info", self.baby.name] andAnimation:YES andDimmedBackground:YES];
        [self.baby saveInBackgroundWithBlock:block];
    } else {
        block(NO, nil);
    }
}

- (void)saveBabyAvatar:(PFBooleanResultBlock)block {
    if (self.baby.avatarImage.isDirty) {
        [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Uploading %@'s photo", self.baby.name] andAnimation:YES andDimmedBackground:YES];
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

- (NSString *)nameFromDeviceName {
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSError *error;
    static NSString *expression = (@"^(?:iPhone|phone|iPad|iPod)\\s+(?:de\\s+)?|"
            "(\\S+?)(?:['’]?s)?(?:\\s+(?:iPhone|phone|iPad|iPod))?$|"
            "(\\S+?)(?:['’]?的)?(?:\\s*(?:iPhone|phone|iPad|iPod))?$|"
            "(\\S+)\\s+");
    static NSRange RangeNotFound = (NSRange) {.location=NSNotFound, .length=0};
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                           options:(NSRegularExpressionCaseInsensitive)
                                                                             error:&error];
    for (NSTextCheckingResult *result in [regex matchesInString:deviceName
                                                        options:0
                                                          range:NSMakeRange(0, deviceName.length)]) {
        for (int i = 1; i < result.numberOfRanges; i++) {
            if (!NSEqualRanges([result rangeAtIndex:i], RangeNotFound)) {
                return [deviceName substringWithRange:[result rangeAtIndex:i]].capitalizedString;
            }
        }
    }
    return nil;
}

@end
