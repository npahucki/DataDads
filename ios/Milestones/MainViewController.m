//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainViewController.h"
#import "CustomIOS7AlertView.h"

@implementation MainViewController {
  UITabBarItem * _notificationsTabItem;
}

-(void) viewDidLoad {
  [super viewDidLoad];
  _notificationsTabItem = ((UIViewController*)[self.viewControllers objectAtIndex:1]).tabBarItem;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) appEnterForeground:(NSNotification*)notice {
  [self updateNotificationTabBadge:-1];
}

-(void) gotPushNotification:(NSNotification*)notice {
  NSNumber * badgeNumber = [[notice.userInfo objectForKey:@"aps"] objectForKey:@"badge"];
  [self updateNotificationTabBadge:badgeNumber.integerValue];
}

-(void) updateNotificationTabBadge:(NSInteger) badge {
  if(self.selectedViewController.tabBarItem == _notificationsTabItem) {
    // clear the notificaiton, we are already on it
    _notificationsTabItem.badgeValue = nil;
    [PFInstallation currentInstallation].badge = 0;
    [[PFInstallation currentInstallation] saveEventually];
  } else {
    if(badge == -1) {
      // use default
      badge = [PFInstallation currentInstallation].badge;
    }
    _notificationsTabItem.badgeValue = badge ? [NSString stringWithFormat:@"%ld", (long)badge] : nil;
  }
}
  
  
- (void)viewDidAppear:(BOOL)animated {
  [self updateNotificationTabBadge:-1];
  
  ParentUser * user = ParentUser.currentUser;
  if(user) {
    [UsageAnalytics idenfity:user withBaby:nil];
    if(Baby.currentBaby == nil) {
      // Finally, we must have at least one baby's info on file
      PFQuery *query =  [Baby  queryForBabiesForUser:PFUser.currentUser];
      query.cachePolicy = [Reachability isParseCurrentlyReachable] ? kPFCachePolicyCacheThenNetwork : kPFCachePolicyCacheOnly;
      __block BOOL cachedResult = YES;
      [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
          // NOTE: This block gets called twice, once for cache, then once for network
          // With the Cache then Network Policy both are always called.
          if([objects count] > 0) {
            // First call will be cache, we use that, then when the network call is complete
            // If and only if the Baby object is different do we replace it and send the notfication again
            Baby *newBaby = [objects firstObject];
            if(![Baby currentBaby] || [newBaby.updatedAt compare:[Baby currentBaby].updatedAt] == NSOrderedDescending) {
              [Baby setCurrentBaby:newBaby];
            }
          } else if(!cachedResult) { // Don't show the baby screen when there are simply no objects in the cache.
            // Must show the enter baby screen since there are none registered yet
            [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
          }
        } else {
          if(error.code != kPFErrorCacheMiss) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Small Problem" message:@"Could not load info for your baby. You may want to check that you have an internet connection and/or try again a little later" delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil];
            [alert show];
            NSLog(@"Error trying to load baby : %@",  error);
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

-(void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
  if(item == _notificationsTabItem) {
    // Reset badge count when the view is shown
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
      currentInstallation.badge = 0;
      [currentInstallation saveEventually];
    }
    item.badgeValue = nil;
  }
}



@end
