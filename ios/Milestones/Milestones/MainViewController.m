//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainViewController.h"
#import "CustomIOS7AlertView.h"

@implementation MainViewController

-(void) viewDidLoad {
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  PFUser * user = PFUser.currentUser;
  if(user) {
    if([Baby currentBaby] == nil) {
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
    
    // TODO: Check to see if baby's info in file
    //[self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
    [super viewDidAppear:animated];
    
  } else {
    // need to login before we can do anything
    [self performSegueWithIdentifier:@"showIntroScreen" sender:self];
  }
}



@end
