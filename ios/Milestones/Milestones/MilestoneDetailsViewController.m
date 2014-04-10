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
  self.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:17];
  self.descriptionLabel.text = self.achievement.standardMilestone.shortDescription ? self.achievement.standardMilestone.shortDescription : @"No Description";
  self.descriptionLabel.font = [UIFont fontForAppWithType:Book andSize:15];
  //self.enteredByLabel.text = self.achievement.standardMilestone.enteredBy;
  self.enteredByLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
  // TODO: format months if more than 30
  self.ageRangeLabel.text = [NSString stringWithFormat:@"Bewteen %@ - %@ days", self.achievement.standardMilestone.rangeLow, self.achievement.standardMilestone.rangeHigh];
  self.ageRangeLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.titleLabel sizeToFit];
  [self.descriptionLabel sizeToFit];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = self.achievement;
}

@end



