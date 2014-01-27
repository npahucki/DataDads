//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController


- (void)viewDidAppear:(BOOL)animated {
  
  PFUser * user = [PFUser currentUser];
  if(user) {
    NSString * screenName = [user objectForKey:kDDUserScreenName];
    if(!screenName || [screenName length] == 0) {
      // Must show the propt to enter a screen name
      [self performSegueWithIdentifier:@"enterScreenName" sender:self];
    } else {
      // Finally, we must have at least one baby's info on file
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
