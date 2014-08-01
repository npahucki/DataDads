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
    self.continueButton.titleLabel.font = self.loginNowButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

@end
