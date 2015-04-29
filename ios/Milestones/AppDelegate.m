//
//  AppDelegate.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <PFCloud+Cache/PFCloud+Cache.h>
#import <AppsFlyer-SDK/AppsFlyerTracker.h>
#import "AppDelegate.h"
#import "hipmob/HMService.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *hipMobAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.HipMobAppId"];
    [[HMService sharedService] setup:hipMobAppId withLaunchOptions:launchOptions];
    
    
    NSString *parseAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.ParseApplicationId"];
    NSLog(@"Using Parse Application Id '%@'", parseAppId);
    [Parse setApplicationId:parseAppId clientKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.ParseClientId"]];
    // Register custom subclasses
    [ParentUser registerSubclass];
    [Baby registerSubclass];
    [Tag registerSubclass];
    [Tip registerSubclass];
    [BabyAssignedTip registerSubclass];
    [StandardMilestone registerSubclass];
    [MilestoneAchievement registerSubclass];
    [Measurement registerSubclass];
    [PurchaseTransaction registerSubclass];
    [FollowConnection registerSubclass];

    [UsageAnalytics initializeAnalytics:launchOptions];
    // Only track for brand new installs, not upgrades.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"installEventSent"] && [defaults stringForKey:@"lastSeenBuild"] == nil) {
        [defaults setBool:YES forKey:@"installEventSent"];
        [UsageAnalytics trackAppInstalled];
    }

    // Force class load and start monitoring network connection.
    [Reachability reachabilityForParseHost];

    // Make sure if this is a new version, we discard the old cache which may cause crashing if incompatible
    if ([self checkIsNewlyInstalledVersion]) {
        [PFCloud clearAllCachedResults];
        [PFQuery clearAllCachedResults];
    }

    // Make sure only users can read their own data!
    [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];
    [PFFacebookUtils initializeFacebook];

    // Setup user tracking and A/B tests
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [ParentUser incrementLaunchCount];

    [UILabel appearance].font = [UIFont fontForAppWithType:Light andSize:17.0];
    [UILabel appearanceWhenContainedIn:[UIDatePicker class], nil].font = [UIFont systemFontOfSize:24.0];

    [UITextField appearance].font = [UIFont fontForAppWithType:Bold andSize:17.0];
    [UITextField appearance].textColor = [UIColor appNormalColor];
    //[UILabel appearanceWhenContainedIn:[UITextField class], nil].textColor = [UIColor appInputGreyTextColor]; // Placeholder
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setClearButtonMode:UITextFieldViewModeNever];

    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:14]} forState:UIControlStateNormal];
    [UISegmentedControl appearance].tintColor = [UIColor appNormalColor];

    [UIButton appearance].titleLabel.font = [UIFont fontForAppWithType:Medium andSize:17.0];
    [UILabel appearanceWhenContainedIn:[UIButton class], nil].font = [UIFont fontForAppWithType:Medium andSize:17];
    [UILabel appearanceWhenContainedIn:[UIButton class], nil].textColor = [UIColor appNormalColor];
    [[UIButton appearance] setTitleColor:[UIColor appNormalColor] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:[UIColor appSelectedColor] forState:UIControlStateHighlighted];
    [[UIButton appearance] setTitleColor:[UIColor appSelectedColor] forState:UIControlStateSelected];


    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:16.0], NSForegroundColorAttributeName : [UIColor appTitleHeaderColor]}];
    [UINavigationBar appearance].tintColor = [UIColor appNormalColor]; // Color of the items in the toolbarheader
    [UINavigationBar appearance].barTintColor = [UIColor appBackgroundColor];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:17.0], NSForegroundColorAttributeName : [UIColor appNormalColor]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:17.0], NSForegroundColorAttributeName : [UIColor grayColor]} forState:UIControlStateDisabled];

    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor appHeaderNormalTextColor]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor appNormalColor]} forState:UIControlStateSelected];
    [UITabBar appearance].selectedImageTintColor = [UIColor appNormalColor];
    [UITabBar appearance].backgroundColor = [UIColor appBackgroundColor];

    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor appGreyTextColor];
    pageControl.currentPageIndicatorTintColor = [UIColor appNormalColor];
    pageControl.backgroundColor = [UIColor whiteColor];

    // There is a bug in PFInstallation, that if saveEventually is used to save it
    // for the first time, then the appVersion, appName and appIdentifier do NOT get set
    // So we need to always try to save it right away before save eventually can ever be called.
    // This should have no effect for PFInstallations that are not new or have not changed.
    [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [UsageAnalytics trackError:error forOperationNamed:@"Initial Installation Save"];
        }

        // Register for push notifications
        if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
            // ios 8
            [application registerUserNotificationSettings:[UIUserNotificationSettings                   settingsForTypes:
                    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [application registerForRemoteNotifications];
        } else {
            // ios 7
            [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }

        // When the app is not open at all, the didReceiveRemoteNotification is not called, we need to detect his here and call it
        // for it to work correctly.
        UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notification) {
            [self application:application didReceiveRemoteNotification:notification.userInfo];
        }
    }];

    // Allow HipMob to open if push was sent when app was closed.
    [[HMService sharedService] onLaunch:launchOptions];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.scheme hasPrefix:@"dataparenting"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationURLOpened object:url];
        [[AppsFlyerTracker sharedTracker] handleOpenURL:url sourceApplication:sourceApplication];
        return YES;
    } else {
        // TODO: Open URL to the invite page.
        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)app {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    [UsageAnalytics trackAppBecameActive];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationNeedDataRefreshNotification object:nil];
    [ParentUser incrementLaunchCount];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[PFFacebookUtils session] close];
}


#pragma mark Push Notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    // NOTE: This is only called if the user allowed at least badge notifications. If the user did not allow any notifications
    // then this method will never get called. Hence, to see how many users allow push, just look at the users without the
    // device token OR pushNotificationType set.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];

    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        currentInstallation[@"pushNotificationType"] = @([application currentUserNotificationSettings].types);
    } else {
        currentInstallation[@"pushNotificationType"] = @([application enabledRemoteNotificationTypes]);
    }
    [currentInstallation saveEventually];
    // So HipMob can send push notifications.
    [[HMService sharedService] setPushToken:newDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // NOTE: This is only called in the case where an incorrect certificate is used to register - such as
    // the production app being run from TestFlight (signed with dev cert).
    // NOTE: This method is NOT called if the user refuses to grant permission for push notifications
    [UsageAnalytics trackError:error forOperationNamed:@"registerForPushNotifications"];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"pushNotificationType"] = @(-1);
    [currentInstallation saveEventually];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSMutableDictionary *newUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
    BOOL openFromBackground = application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground;
    newUserInfo[kDDPushNotificationField_OpenedFromBackground] = @(openFromBackground);
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationPushReceived object:self userInfo:newUserInfo];
    if (openFromBackground) {
        [[PFInstallation currentInstallation] incrementKey:@"pushNotificationActivateCount" byAmount:@(1)];
        [[PFInstallation currentInstallation] saveEventually];
    }
    // Let HipMob handle any of its own push messages.
    [[HMService sharedService] onPushNotificationReceived:userInfo];
}


// Side effect is that after called, the last seen version is set, thus this should be called just once
// each app startup. If called twice in a row after a new install, the first call will return YES, but the second false
- (BOOL)checkIsNewlyInstalledVersion {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *currentVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *currentBuild = infoDictionary[(NSString *) kCFBundleVersionKey];

    NSString *lastSeenVersion = [defaults stringForKey:@"lastSeenVersion"];
    NSString *lastSeenBuild = [defaults stringForKey:@"lastSeenBuild"];

    if ([currentVersion isEqualToString:lastSeenVersion] && [currentBuild isEqualToString:lastSeenBuild]) {
        return NO;
    } else {
        [defaults setObject:currentVersion forKey:@"lastSeenVersion"];
        [defaults setObject:currentBuild forKey:@"lastSeenBuild"];
        return YES;
    }
}

@end
