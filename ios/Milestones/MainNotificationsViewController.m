//
//  NotificationsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MainNotificationsViewController.h"
#import "NotificationTableViewController.h"
#import "NoConnectionAlertView.h"
#import "UIImage+FX.h"
#import "SignUpViewController.h"

@interface MainNotificationsViewController ()

@end

@implementation MainNotificationsViewController {
    NotificationTableViewController *_tableController;
    NSInteger _currentBadge;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    // Register here so we can handle these in the background, EVEN if the tab has never been selected
    // since selecting the tab the first time is what triggers viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipAssignmentViewedOrHidden:) name:kDDNotificationTipAssignmentViewedOrHidden object:nil];
    _currentBadge = -1;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NoConnectionAlertView createInstanceForController:self];
    // Since controller loads after baby is set, we need to run the code to update the button icon.
    [self updateBabyInfo:Baby.currentBaby];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.babyMenuButton.enabled = Baby.currentBaby != nil;
    BOOL isAnonymous =  [PFAnonymousUtils isLinkedWithUser:PFUser.currentUser];
    self.containerView.hidden = isAnonymous;
    self.signUpContainerView.hidden = !isAnonymous;

    if (![ParentUser currentUser].email) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Sign Up" message:@"To see useful tips, SIGN-UP now. We'll also back-up your milestones and photos."
                                                       delegate:nil
                                              cancelButtonTitle:@"Maybe Later"
                                              otherButtonTitles:@"Sign Up", nil];
        [alert showWithButtonBlock:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                SignUpViewController *signupController = [[SignUpViewController alloc] init];
                signupController.showExternal = YES;
                [self presentViewController:signupController animated:YES completion:nil];
            }
        }];
    }
}

- (void)ensureInitialBadgeValueSet:(BOOL)force playSoundIfUpdated:(BOOL)useSound {
    if ((_currentBadge == -1 || force) && Baby.currentBaby) {
        [PFCloud callFunctionInBackground:@"tipBadgeCount"
                           withParameters:@{@"babyId" : Baby.currentBaby.objectId,
                                   @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                                   @"showHiddenTips" : @(ParentUser.currentUser.showHiddenTips)}
                                    block:^(NSDictionary *objects, NSError *error) {
                                        NSNumber *badge = objects[@"badge"];
                                        if (badge) {
                                            if (_currentBadge != badge.integerValue) {
                                                _currentBadge = badge.integerValue;
                                                [self updateBadgeFromCurrent];
                                                if (useSound) {
                                                    AudioServicesPlaySystemSound(1003);
                                                }
                                            }

                                        }
                                    }];
    }
}


- (void)tipAssignmentViewedOrHidden:(NSNotification *)notice {
    BabyAssignedTip *tipAssignment = notice.object;
    if (_currentBadge == -1) {
        [self ensureInitialBadgeValueSet:NO playSoundIfUpdated:NO];
    } else {
        // Don't decrement the count, if a previously viewed tip has been hidden
        if (!(tipAssignment.isHidden && tipAssignment.viewedOn)) {
            if (_currentBadge > 0) {
                _currentBadge--;
            }
            [self updateBadgeFromCurrent];
        }
    }
}

- (void)gotPushNotification:(NSNotification *)notice {
    // First check if it is a tipsNotification, ignore if not.
    if ([kDDPushNotificationTypeTip isEqualToString:notice.userInfo[kDDPushNotificationField_CData][kDDPushNotificationField_Type]]) {
        if (((NSNumber *) notice.userInfo[kDDPushNotificationField_OpenedFromBackground]).boolValue) {
            // Make this the currently selected tab
            self.navigationController.tabBarController.selectedViewController = self.navigationController;
        }
        [_tableController loadObjects];
        [self ensureInitialBadgeValueSet:YES playSoundIfUpdated:YES];
    }
}

- (void)updateBadgeFromCurrent {
    self.navigationController.tabBarItem.badgeValue = _currentBadge > 0 ? @(_currentBadge).stringValue : nil;
}

- (void)appEnterForeground:(NSNotification *)notice {
    [_tableController loadObjects];
    [self ensureInitialBadgeValueSet:YES playSoundIfUpdated:NO];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // The only segue is the embed
    if ([segue.destinationViewController isKindOfClass:[NotificationTableViewController class]]) {
        _tableController = (NotificationTableViewController *) segue.destinationViewController;
    }
}

- (void)babyUpdated:(NSNotification *)notification {
    Baby *baby = (Baby *) notification.object;
    [self updateBabyInfo:baby];
    [self ensureInitialBadgeValueSet:YES playSoundIfUpdated:NO];
}

- (void)updateBabyInfo:(Baby *)baby {
    self.babyMenuButton.enabled = baby != nil;

    PFFile *imageFile = baby.avatarImageThumbnail ? baby.avatarImageThumbnail : baby.avatarImage;
    if (imageFile) {
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [[UIImage alloc] initWithData:data];
                if (image) {
                    [self.babyMenuButton setImage:image forState:UIControlStateNormal];
                    [self.babyMenuButton setImage:[image imageWithAlpha:.70] forState:UIControlStateHighlighted];
                    self.babyMenuButton.layer.borderColor = [UIColor appNormalColor].CGColor;

                    CALayer *innerShadowLayer = [CALayer layer];
                    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
                    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
                    innerShadowLayer.frame = CGRectInset(self.babyMenuButton.bounds, 2.5, 2.5);
                    [self.babyMenuButton.layer addSublayer:innerShadowLayer];
                    self.babyMenuButton.layer.borderWidth = 3;
                    self.babyMenuButton.layer.cornerRadius = self.babyMenuButton.bounds.size.width / 2;
                    self.babyMenuButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    self.babyMenuButton.clipsToBounds = YES;
                    self.babyMenuButton.showsTouchWhenHighlighted = YES;
                }
            }
        }];
    }
}


@end
