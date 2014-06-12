//
//  SettingPanelViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "SettingPanelViewController.h"

@interface SettingPanelViewController ()

@end

@implementation SettingPanelViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.useMetricSwitch.on = ParentUser.currentUser.usesMetric;

  for(UIView * view in self.view.subviews) {
    if([view isKindOfClass:[UILabel class]]) {
      UILabel * label = (UILabel *) view;
      label.font = [UIFont fontForAppWithType:Book andSize:15];
      label.textColor = [UIColor appGreyTextColor];
    }
  }
}

- (IBAction)didChangeUseMetricSwitch:(id)sender {
  ParentUser.currentUser.usesMetric = self.useMetricSwitch.on;
}

-(void) viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if(ParentUser.currentUser.isDirty) {
    [ParentUser.currentUser saveEventually];
  }
}


@end
