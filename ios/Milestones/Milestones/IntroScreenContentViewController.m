//
//  IntroScreenViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/15/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "IntroScreenContentViewController.h"

@implementation IntroScreenContentViewController


-(void) viewDidLoad {
  [super viewDidLoad];
  self.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
  self.titleLabel.textColor = [UIColor appGreyTextColor];
  self.titleLabel.text = self.text;
  [self.titleLabel sizeToFit];
  self.closeButton.hidden = !self.last;
}

- (IBAction)didClickCloseButton:(id)sender {
  // TODO Close!
}

@end
