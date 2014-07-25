//
//  IntroScreenPageViewController.m
//  
//
//  Created by Nathan  Pahucki on 5/15/14.
//
//

#import "IntroScreenPageViewController.h"

@interface IntroScreenPageViewController ()

@end

@implementation IntroScreenPageViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginNowButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    self.continueButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

@end
