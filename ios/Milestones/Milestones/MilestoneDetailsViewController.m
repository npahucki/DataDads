//
//  MilestoneDetailsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 2/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MilestoneDetailsViewController.h"

@interface MilestoneDetailsViewController ()

@end

@implementation MilestoneDetailsViewController



- (void)viewDidLoad
{
  [super viewDidLoad];
  self.titleLabel.text = self.milestone.title;
  //[self.titleLabel sizeToFit];
  self.descriptionLabel.text = self.milestone.shortDescription;
  //[self.descriptionLabel sizeToFit];
  // TODO: format months if more than 30
  self.ageRangeLabel.text = [NSString stringWithFormat:@"%@ - %@ days", self.milestone.rangeLow, self.milestone.rangeHigh];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.presentingViewController dismissViewControllerAnimated:YES                                                    completion:nil];
}

@end
