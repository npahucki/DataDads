//
//  NotificationsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainNotificationsViewController.h"
#import "CustomIOS7AlertView.h"

@interface MainNotificationsViewController ()

@end

@implementation MainNotificationsViewController {
  BOOL _isMorganTouch;
}


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kDDNotificationCurrentBabyChanged object:nil];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  //self.menuButton.enabled = Baby.currentBaby != nil;
  _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
  
  BOOL isAnonymous = !PFUser.currentUser.email;
  self.containerView.hidden = isAnonymous;
  self.signUpContainerView.hidden = !isAnonymous;
}

-(void) babyUpdated:(NSNotification*)notification {
  //self.menuButton.enabled = Baby.currentBaby != nil;
  self.navigationItem.title = Baby.currentBaby.name;
}



@end
