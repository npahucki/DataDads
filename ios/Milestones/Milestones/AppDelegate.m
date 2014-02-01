//
//  AppDelegate.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  
  // Register custom subclasses
  [Baby registerSubclass];
  [Tag registerSubclass];
  [StandardMilestone registerSubclass];
  [StandardMilestoneAchievement registerSubclass];
  
  // Setup Social Providers
  [Parse setApplicationId:@"NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U"
                clientKey:@"iMYPq4Fg751JyIOeHYnDH4LsuivOcm8uoi4DlwJ9"];
  [PFFacebookUtils initializeFacebook];
  [PFTwitterUtils initializeWithConsumerKey:@"4UXzyDxzZSDXwfCw1qK4ew"
                             consumerSecret:@"lzARes6UFvuHTynV0EleL1lmSclmv99k1AXuz5XeAk"];

  // Setup user tracking and A/B tests
  [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
  
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
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
