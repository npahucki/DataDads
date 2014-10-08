//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "MainViewController.h"
#import "SignUpViewController.h"

#define NOTIFICATION_CONTROLLER_ID @"notificationNavigationController"

@implementation MainViewController {
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

- (void)viewDidLoad {
    self.delegate = self;
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut) name:kDDNotificationUserLoggedOut object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appEnterForeground:(NSNotification *)notice {
    [self updateNotificationTabBadge:-1];
}

- (void)gotPushNotification:(NSNotification *)notice {
    NSNumber *badgeNumber = notice.userInfo[@"aps"][@"badge"];
    [self updateNotificationTabBadge:badgeNumber.integerValue];
}

- (void)userDidLogOut {
    // Put us back on the main screen.
    [self.tabBarController setSelectedIndex:0];
}

- (UIViewController *)notificationViewController {
    UIViewController *controller = nil;
    for (controller in self.viewControllers) {
        if ([controller.restorationIdentifier isEqualToString:NOTIFICATION_CONTROLLER_ID]) {
            break;
        }
    }
    return controller;
}

- (void)updateNotificationTabBadge:(NSInteger)badge {
    // Find notifications view controller
    UIViewController *controller = [self notificationViewController];
    UITabBarItem *notificationsTabItem = controller.tabBarItem;

    if (self.selectedViewController.tabBarItem == notificationsTabItem) {
        // clear the notification, we are already on it
        notificationsTabItem.badgeValue = nil;
        [PFInstallation currentInstallation].badge = 0;
        [[PFInstallation currentInstallation] saveEventually];
    } else {
        if (badge == -1) {
            // use default
            badge = [PFInstallation currentInstallation].badge;
        }
        notificationsTabItem.badgeValue = badge ? [NSString stringWithFormat:@"%ld", (long) badge] : nil;
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [self updateNotificationTabBadge:-1];

    ParentUser *user = ParentUser.currentUser;
    if (user) {
        [UsageAnalytics idenfity:user withBaby:nil];
        if (Baby.currentBaby == nil) {
            // Finally, we must have at least one baby's info on file
            PFQuery *query = [Baby queryForBabiesForUser:PFUser.currentUser];
            query.cachePolicy = [Reachability isParseCurrentlyReachable] ? kPFCachePolicyCacheThenNetwork : kPFCachePolicyCacheOnly;
            __block BOOL cachedResult = YES;
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    // NOTE: This block gets called twice, once for cache, then once for network
                    // With the Cache then Network Policy both are always called.
                    if ([objects count] > 0) {
                        // First call will be cache, we use that, then when the network call is complete
                        // If and only if the Baby object is different do we replace it and send the notfication again
                        Baby *newBaby = [objects firstObject];
                        if (![Baby currentBaby] || [newBaby.updatedAt compare:[Baby currentBaby].updatedAt] == NSOrderedDescending) {
                            [Baby setCurrentBaby:newBaby];
                            if (newBaby) [self showTutorialPromptIfNeeded:user];
                        }
                    } else if (!cachedResult) { // Don't show the baby screen when there are simply no objects in the cache.
                        // Must show the enter baby screen since there are none registered yet
                        [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
                    }
                } else {
                    if (error.code != kPFErrorCacheMiss) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Small Problem" message:@"Could not load info for your baby. You may want to check that you have an internet connection and/or try again a little later" delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil];
                        [alert show];
                        NSLog(@"Error trying to load baby : %@", error);
                    }
                }

                // Flip the bit
                if (cachedResult) {
                    cachedResult = NO;
                }
            }];
        }
        [UsageAnalytics idenfity:user withBaby:Baby.currentBaby];
        [super viewDidAppear:animated];
    } else {
        [self performSegueWithIdentifier:@"showIntroScreen" sender:self];
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController.restorationIdentifier isEqualToString:NOTIFICATION_CONTROLLER_ID]) {
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

    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController.restorationIdentifier isEqualToString:NOTIFICATION_CONTROLLER_ID]) {
        // Reset badge count when the view is shown
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
        }
        viewController.tabBarItem.badgeValue = nil;
    }

}

- (void)showTutorialPromptIfNeeded:(ParentUser *)user {
    if (!user.shownTutorialPrompt) {
        user.shownTutorialPrompt = YES;
        [[[UIAlertView alloc] initWithTitle:@"Take a Quick Tour?"
                                    message:@"Do you want to see a quick tour about how things work? You can view it under 'account settings' anytime."
                                   delegate:nil
                          cancelButtonTitle:@"Not Now"
                          otherButtonTitles:@"Yes", nil] showWithButtonBlock:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self performSegueWithIdentifier:@"showTutorial" sender:self];
                [UsageAnalytics trackTutorialResponse:YES];
            } else {
                [UsageAnalytics trackTutorialResponse:NO];
            }
        }];
    }
}


@end
