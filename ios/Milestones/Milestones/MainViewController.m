//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

-(void) viewDidLoad {
  [super viewDidLoad];
  // Whenever the current baby chnages, we need to refresh the table
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
}

-(void) babyUpdated:(NSNotification*)notification {
  _myBaby =  [notification.userInfo objectForKey:@""];
}

- (void)viewDidAppear:(BOOL)animated {
  
  PFUser * user = PFUser.currentUser;
  if(user) {
    NSString * screenName = [user objectForKey:kDDUserScreenName];
    if(![screenName length]) {
      // Must show the propt to enter a screen name
      // TODO: Set a default screen name based on Facebook name or user name.
      if([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        // TODO: Lookup Name in facebook to suggest as screen name
      } else {
        [user setObject:user.username forKey:kDDUserScreenName];
      }
      [self performSegueWithIdentifier:@"enterScreenName" sender:self];
    } else {
      if(_myBaby == nil) {
        // Finally, we must have at least one baby's info on file
        PFQuery *query =  [Baby  queryForBabiesForUser:PFUser.currentUser];
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        __block BOOL cachedResult = YES;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
          if (!error) {
            // NOTE: This block gets called twice, once for cache, then once for network
            // With the Cache then Network Policy both are always called.
            if([objects count] > 0) {
              // First call will be cache, we use that, then when the network call is complete
              // If and only if the Baby object is different do we replace it and send the notfication again
              Baby *newBaby = [objects firstObject];
              if(!_myBaby || [newBaby.updatedAt compare:_myBaby.updatedAt] == NSOrderedDescending) {
                _myBaby = newBaby;
                // Let other view controllers know the current baby has changed so they can update thir views
                [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationCurrentBabyChanged object:self userInfo:[NSDictionary dictionaryWithObject:_myBaby forKey:@""]];
              }
            } else if(!cachedResult) { // Don't show the baby screen when there are simply no objects in the cache.
              // Must show the enter baby screen since there are none registered yet
              [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
            }
          } else {
            if(error.code != kPFErrorCacheMiss) { // ignore cache miss
              // TODO: display error to end user
              NSLog(@"Could not load the list of babies now, must try later %@", error);
            }
          }

          // Flip the bit
          if (cachedResult) {
            cachedResult = NO;
          }
        }];
      }
      
      // TODO: Check to see if baby's info in file
      //[self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
      [super viewDidAppear:animated];
    }
    
  } else {
    // need to login before we can do anything
    [self performSegueWithIdentifier:@"login" sender:self];
  }
}





@end
