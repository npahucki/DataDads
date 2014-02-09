//
//  FirstViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PickMilestoneViewController.h"
#import "NoteMilestoneViewController.h"
#import "CreateMilestoneViewController.h"

@interface PickMilestoneViewController ()

@end

@implementation PickMilestoneViewController




-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:@"embedTable"]) {
    self.tableViewController = (PickAMilestoneTableViewController*) segue.destinationViewController;
  } else if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.baby = self.tableViewController.baby;
    ((CreateMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  }
}

@end
