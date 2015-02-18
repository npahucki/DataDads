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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tipAssignmentViewedOrHidden:) name:kDDNotificationTipAssignmentViewedOrHidden object:nil];
    _currentBadge = -1;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NoConnectionAlertView createInstanceForController:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BOOL isAnonymous =  [PFAnonymousUtils isLinkedWithUser:PFUser.currentUser];
    self.containerView.hidden = isAnonymous;
    self.signUpContainerView.hidden = !isAnonymous;
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
    [super babyUpdated:notification];
    [self ensureInitialBadgeValueSet:YES playSoundIfUpdated:NO];
}



@end
