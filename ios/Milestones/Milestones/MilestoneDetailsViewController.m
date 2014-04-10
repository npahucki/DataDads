//
//  MilestoneDetailsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 2/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MilestoneDetailsViewController.h"
#import "NoteMilestoneViewController.h"

@interface MilestoneDetailsViewController ()

@end

@implementation MilestoneDetailsViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.titleLabel.text = self.achievement.standardMilestone.title;
  self.descriptionLabel.text = self.achievement.standardMilestone.shortDescription ? self.achievement.standardMilestone.shortDescription : @"No Description";
  //self.enteredByLabel = self.achievement.standardMilestone.
  // TODO: format months if more than 30
  self.ageRangeLabel.text = [NSString stringWithFormat:@"%@ - %@ days", self.achievement.standardMilestone.rangeLow, self.achievement.standardMilestone.rangeHigh];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = self.achievement;
}

@end



