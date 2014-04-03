//
//  SettingsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "SettingsViewController.h"
#import "Baby.h"

@implementation SettingsViewController


-(void) viewDidLoad {
  NSAssert(Baby.currentBaby.name, @"Expected a current baby would be set before setting invoked");
  self.babyNameLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:21.0];
  self.babyNameLabel.text = Baby.currentBaby.name;
  self.ageLabel.font = [UIFont fontWithName:@"GothamRounded-Medium" size:18.0];
  self.ageLabel.text = [self ageFormatedAsNiceString:Baby.currentBaby.daysSinceBirth];
}

- (IBAction)doneButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)accountButtonClicked:(id)sender {
}

- (IBAction)historyButtonClicked:(id)sender {
}

-(NSString*) ageFormatedAsNiceString: (NSInteger) days {
  return [NSString stringWithFormat:@"%ld days old",days];
//  if(days >= 365){
//    float years = round(days / 365) / 2.0f;
//    period = (years > 1) ? @"years" : @"year";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", years, period];
//  } else if(days < 365 && days >= 30) {
//    float months = round(days / 30) / 2.0f;
//    period = (months > 1) ? @"months" : @"month";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", months, period];
//  } else if(days < 30 && days >= 2) {
//    period = @"days";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", days, period];
//  } else if(days == 1){
//    period = @"day";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", days, period];
//  } else if(days < 1 && minutes > 60) {
//    period = (hours > 1) ? @"hours" : @"hour";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", hours, period];
//  } else {
//    period = (minutes < 60 && minutes > 1) ? @"minutes" : @"minute";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", minutes, period];
//    if(minutes < 1){
//      formatted = @"a moment ago";
//    }
//  }
//  return formatted;
}


@end
