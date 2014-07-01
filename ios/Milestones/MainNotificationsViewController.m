//
//  NotificationsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainNotificationsViewController.h"
#import "CustomIOS7AlertView.h"
#import "NotificationTableViewController.h"
#import "NoConnectionAlertView.h"

@interface MainNotificationsViewController ()

@end

@implementation MainNotificationsViewController {
  NotificationTableViewController * _tableController;
  BOOL _isMorganTouch;
}

- (IBAction)didChangeFilter:(id)sender {
  UISegmentedControl * ctl = (UISegmentedControl*)sender;
  switch(ctl.selectedSegmentIndex) {
    case 0:
      _tableController.tipFilter = TipTypeNormal;
      break;
    case 1:
      _tableController.tipFilter = TipTypeWarning;
      break;
    default:
      _tableController.tipFilter = 0; // All
      break;
  }
}


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];
  
  [NoConnectionAlertView createInstanceForController:self];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
}

-(void) appEnterForeground:(NSNotification*)notice {
  [_tableController loadObjects];
}

-(void) gotPushNotification:(NSNotification*)notice {
  [_tableController loadObjects];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // The only segue is the embed
  if([segue.destinationViewController isKindOfClass:[NotificationTableViewController class]]) {
    _tableController = (NotificationTableViewController*) segue.destinationViewController;
  }
}



@end
