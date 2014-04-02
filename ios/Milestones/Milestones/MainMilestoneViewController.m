//
//  MainMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainMilestoneViewController.h"
#import "CreateMilestoneViewController.h"

@implementation MainMilestoneViewController


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  self.babyNameLabel.font =  [UIFont fontWithName:@"GothamRounded-Bold" size:21.0];
  self.babyNameLabel.text = nil; // remove place holder text
}

- (IBAction)didPressShowMenuButton:(id)sender {
}


-(void) babyUpdated:(NSNotification*)notification {
  self.baby =  [notification.userInfo objectForKey:@""];
  self.babyNameLabel.text = self.baby.name;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  MilestoneAchievement * achievement = [MilestoneAchievement object];
  achievement.baby = self.baby;
  if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    ((CreateMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  }
}

@end
