//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainViewController.h"
#import "Baby.h"

@implementation MainViewController


- (void)viewDidAppear:(BOOL)animated {
  
  PFUser * user = PFUser.currentUser;
  if(user) {
    NSString * screenName = [user objectForKey:kDDUserScreenName];
    if(!screenName || [screenName length] == 0) {
      // Must show the propt to enter a screen name
      [self performSegueWithIdentifier:@"enterScreenName" sender:self];
    } else {
      if(myBaby == nil) {
        // Finally, we must have at least one baby's info on file
        PFQuery *query =  [Baby  query];
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        [query whereKey:@"parentUserId" equalTo:PFUser.currentUser.objectId];
        // TODO:  wait indicator
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
          if (!error) {
            if([objects count] > 0) {
              myBaby = objects[0];
            } else {
              // Must show the enter baby screen since there are none registered yet
              [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
            }
          } else {
            // TODO: display error to end user
            NSLog(@"Could not load the list of babies now, must try later %@", error);
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
