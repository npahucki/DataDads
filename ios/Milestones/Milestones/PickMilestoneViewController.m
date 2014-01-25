//
//  FirstViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PickMilestoneViewController.h"
#import <Parse/Parse.h>

@interface PickMilestoneViewController ()

@end

@implementation PickMilestoneViewController

  BOOL loggedIn = NO;

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if(!loggedIn) { // TOOD: Logged in check
    loggedIn = YES;
    [[self parentViewController] performSegueWithIdentifier:@"login" sender:self];
  }
  

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
