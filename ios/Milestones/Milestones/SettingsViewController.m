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
  [super viewDidLoad];
  NSAssert(Baby.currentBaby.name, @"Expected a current baby would be set before setting invoked");
  self.babyNameLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:21.0];
  self.babyNameLabel.text = Baby.currentBaby.name;
  self.ageLabel.font = [UIFont fontWithName:@"GothamRounded-Medium" size:18.0];
  self.ageLabel.text = [self timeDifferenceFormatedAsNiceString:Baby.currentBaby.birthDate];

  self.babyAvatar.file = Baby.currentBaby.avatarImage;
  [self.babyAvatar loadInBackground];
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.babyAvatar.layer setCornerRadius:self.babyAvatar.frame.size.width/2];
  self.babyAvatar.layer.masksToBounds = YES;
  self.babyAvatar.layer.borderWidth = 1;
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}


- (IBAction)doneButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSString*) timeDifferenceFormatedAsNiceString: (NSDate*) date {
  unsigned int unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *comps = [calendar components:unitFlags fromDate:date toDate:[NSDate date]  options:0];
  NSString * format = @"";
  if(comps.year >= 1) format = [NSString stringWithFormat:@"%li year%s ",comps.year, [self s:comps.year]];
  if(comps.month >= 1) format = [NSString stringWithFormat:@"%@%li month%s ",format, comps.month, [self s:comps.month]];
  if(comps.day >= 1) format = [NSString stringWithFormat:@"%@%li day%s ",format, comps.day, [self s:comps.day]];
  return [NSString stringWithFormat:@"%@old",format];
}

-(char*) s:(NSInteger) number {
  return number != 1 ? "s" : "";
}




@end
