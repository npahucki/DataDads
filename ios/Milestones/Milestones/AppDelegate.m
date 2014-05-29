//
//  AppDelegate.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "LoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  // Force class load and start monitoring network connection.
  [Reachability reachabilityForParseHost];
  
  // Register custom subclasses
  [Baby registerSubclass];
  [Tag registerSubclass];
  [Tip registerSubclass];
  [BabyAssignedTip registerSubclass];
  [StandardMilestone registerSubclass];
  [MilestoneAchievement registerSubclass];
  
  // Setup Social Providers
  
# if DEBUG || TARGET_IPHONE_SIMULATOR
  NSLog(@"Using Parse DEV account");
  [Parse setApplicationId:@"NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U"
                clientKey:@"iMYPq4Fg751JyIOeHYnDH4LsuivOcm8uoi4DlwJ9"];
#else
  NSLog(@"Using Parse PRODUCTION account");
  [Parse setApplicationId:@"Vxvqum0HRF1NB00LEf2faaJYFzxd2Xh8hyrdY8MY"
                clientKey:@"N4kS8ush3bY6Arb05tI86Gx9uA2EDiZEqzpVDrvq"];
#endif

  [PFFacebookUtils initializeFacebook];
//  [PFTwitterUtils initializeWithConsumerKey:@"4UXzyDxzZSDXwfCw1qK4ew"
//                             consumerSecret:@"lzARes6UFvuHTynV0EleL1lmSclmv99k1AXuz5XeAk"];
  //[PFUser enableAutomaticUser]; // Allows anonymous users
  
  // Setup user tracking and A/B tests
  [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
  
  
  [UILabel appearance].font = [UIFont fontForAppWithType:Light andSize:17.0];
  [UILabel appearanceWhenContainedIn:[UIDatePicker class], nil].font = [UIFont systemFontOfSize:24.0];
  
  [UITextField appearance].font =[UIFont fontForAppWithType:Bold andSize:17.0];
  [UITextField appearance].textColor = [UIColor appNormalColor];
  //[UITextView appearance].font = [UIFont fontForAppWithType:Bold andSize:17.0];
  //[UITextView appearance].textColor = [UIColor appGreyTextColor];

  [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:14]} forState:UIControlStateNormal];
  [UISegmentedControl appearance].tintColor = [UIColor appNormalColor];
  
  [UIButton appearance].titleLabel.font = [UIFont fontForAppWithType:Medium andSize:17.0];
  [UILabel appearanceWhenContainedIn:[UIButton class], nil].font = [UIFont systemFontOfSize:17.0];
  [UILabel appearanceWhenContainedIn:[UIButton class], nil].textColor = [UIColor appNormalColor];
  [[UIButton appearance] setTitleColor:[UIColor appNormalColor] forState:UIControlStateNormal];
  [[UIButton appearance] setTitleColor:[UIColor appSelectedColor] forState:UIControlStateHighlighted];
  [[UIButton appearance] setTitleColor:[UIColor appSelectedColor] forState:UIControlStateSelected];
  
  
  [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:18.0]}];
  [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header.png"] forBarMetrics:UIBarMetricsDefault];
  [UINavigationBar appearance].tintColor = [UIColor appNormalColor];
  [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:17.0], NSForegroundColorAttributeName : [UIColor appNormalColor]} forState:UIControlStateNormal];
  [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:17.0], NSForegroundColorAttributeName : [UIColor appSelectedColor]} forState:UIControlStateHighlighted];
  [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:17.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]} forState:UIControlStateDisabled];

  [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:13.0]} forState:UIControlStateNormal];
  [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:13.0], NSBackgroundColorAttributeName : [UIColor appSelectedColor]} forState:UIControlStateHighlighted];
  [UITabBar appearance].selectedImageTintColor = [UIColor appNormalColor];

  UIPageControl *pageControl = [UIPageControl appearance];
  pageControl.pageIndicatorTintColor =  [UIColor appGreyTextColor];
  pageControl.currentPageIndicatorTintColor = [UIColor appNormalColor];
  pageControl.backgroundColor = [UIColor whiteColor];

  return YES;

}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  //return [PFFacebookUtils handleOpenURL:url]; - deprecated, use the below line instead
  return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
