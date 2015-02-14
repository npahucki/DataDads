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

    NSString *launchImage;
    if  ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
         ([UIScreen mainScreen].bounds.size.height > 480.0f)) {
        launchImage = @"LaunchImage-700-568h";
    } else {
        launchImage = @"LaunchImage-700";
    }
    
    self.backgroundImage.image = [UIImage imageNamed:launchImage];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
