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
  self.milestoneCountLabel = [[UILabel alloc] initWithFrame:self.babyAvatar.frame];
  self.milestoneCountLabel.numberOfLines = 2;
  self.milestoneCountLabel.textAlignment = NSTextAlignmentCenter;
  self.milestoneCountLabel.textColor = self.ageLabel.textColor; // use same as age
  
  self.babyNameLabel.font = [UIFont fontForAppWithType:Bold andSize:21.0];
  self.babyNameLabel.text = Baby.currentBaby.name;
  self.ageLabel.font = [UIFont fontForAppWithType:Medium andSize:18.0];
  self.ageLabel.text = [self timeDifferenceFormatedAsNiceString:Baby.currentBaby.birthDate];

  self.babyAvatar.file = Baby.currentBaby.avatarImage;
  [self.babyAvatar loadInBackground];
  
  PFQuery * query = [MilestoneAchievement query];
  [query whereKey:@"baby" equalTo:Baby.currentBaby];
  [query setCachePolicy:kPFCachePolicyNetworkElseCache];
  [query whereKey:@"isSkipped" notEqualTo:[NSNumber numberWithBool:YES]];
  [query whereKey:@"isPostponed" notEqualTo:[NSNumber numberWithBool:YES]];
  
  [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
    // Make the label show attributed text 
    NSDictionary *numberAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:95.0], NSForegroundColorAttributeName: [UIColor appBlueColor]};
    NSDictionary *milestoneTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:18.0], NSForegroundColorAttributeName: [UIColor appGreyTextColor]};
    NSMutableAttributedString *milestoneString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i\nmilestones logged",number]];
    NSUInteger numLen = [[@(number) stringValue] length];
    [milestoneString setAttributes:numberAttributes range:NSMakeRange(0, numLen)];
    [milestoneString setAttributes:milestoneTextAttributes range:NSMakeRange(numLen + 1,[milestoneString length] - numLen - 1)];
    self.milestoneCountLabel.attributedText = milestoneString;
    
    [self.view addSubview:self.milestoneCountLabel];
    [UILabel animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionTransitionNone animations:^{
      // Causes crash on device
      //self.milestoneCountLabel.transform = CGAffineTransformScale(self.milestoneCountLabel.transform, 0.05, 0.05);
      //self.milestoneCountLabel.center = self.babyAvatar.center;
      self.milestoneCountLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
      [self.milestoneCountLabel removeFromSuperview];
    }];
    [UIImageView animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionTransitionNone animations:^{
      self.babyAvatar.alpha = 1.0;
    } completion:^(BOOL finished) {
      self.babyAvatar.alpha = 1.0;
    }];
  }];
  
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.babyAvatar.layer setCornerRadius:self.babyAvatar.frame.size.width/2];
  self.babyAvatar.layer.masksToBounds = YES;
  self.babyAvatar.layer.borderWidth = 1;
  // This must be done after the final sizes for the image have been calculated, that's why it's not in viewDidLoad
  self.milestoneCountLabel.frame = self.babyAvatar.frame; // Put label ontop of image
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}


- (IBAction)doneButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)logoutButtonPressed:(id)sender {
  [PFUser logOut];
  Baby.currentBaby = nil;
  [self dismissViewControllerAnimated:NO completion:nil];
}

-(NSString*) timeDifferenceFormatedAsNiceString: (NSDate*) date {
  unsigned int unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *comps = [calendar components:unitFlags fromDate:date toDate:[NSDate date]  options:0];
  NSString * format = @"";
  if(comps.year >= 1) format = [NSString stringWithFormat:@"%i year%s ",(int)comps.year, [self s:comps.year]];
  if(comps.month >= 1) format = [NSString stringWithFormat:@"%@%i month%s ",format, (int)comps.month, [self s:comps.month]];
  if(comps.day >= 1) format = [NSString stringWithFormat:@"%@%i day%s ",format, (int)comps.day, [self s:comps.day]];
  return [NSString stringWithFormat:@"%@old",format];
}

-(char*) s:(NSInteger) number {
  return number != 1 ? "s" : "";
}




@end
