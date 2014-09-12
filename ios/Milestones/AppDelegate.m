//
//  AppDelegate.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [UsageAnalytics initializeAnalytics];

    // Force class load and start monitoring network connection.
    [Reachability reachabilityForParseHost];

    // Register custom subclasses
    [Baby registerSubclass];
    [Tag registerSubclass];
    [Tip registerSubclass];
    [BabyAssignedTip registerSubclass];
    [StandardMilestone registerSubclass];
    [MilestoneAchievement registerSubclass];
    [Measurement registerSubclass];
    [ParentUser registerSubclass];
    [PurchaseTransaction registerSubclass];

    // Make sure only users can read their own data!
    [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];

    NSString *parseAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.ParseApplicationId"];
    NSLog(@"Using Parse Application Id '%@'", parseAppId);
    [Parse setApplicationId:parseAppId clientKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.ParseClientId"]];

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


    // TODO: Move this
    [PFPurchase addObserverForProduct:@"video.1" block:^(SKPaymentTransaction *transaction) {
        // TODO: CLoud function to activate the purchase.
        NSLog(@"Bought Product! State:%d", transaction.transactionState);
    }];


    return YES;

}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    // Register for push notifications
    // TODO: Do this only if the user is logged in.
    [application registerForRemoteNotificationTypes:
            UIRemoteNotificationTypeBadge |
                    UIRemoteNotificationTypeAlert |
                    UIRemoteNotificationTypeSound];
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
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation[@"pushNotificationType"] = @([[UIApplication sharedApplication] enabledRemoteNotificationTypes]);
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for push noticiations :%@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Hope this does not get us rejected if it does use :
    //      https://developer.apple.com/library/ios/samplecode/SysSound/Introduction/Intro.html
    AudioServicesPlaySystemSound(1003);
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationPushReceieved object:self userInfo:userInfo];
}

@end
