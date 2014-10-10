//
//  OnboardingStepViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/10/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "OnboardingStepViewController.h"

@interface OnboardingStepViewController ()

@end

@implementation OnboardingStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.prompt = [NSString stringWithFormat:@"Step %d of %d", (int) self.currentStepNumber, (int) self.totalSteps];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController <ViewControllerWithBaby> *controller = (UIViewController <ViewControllerWithBaby> *) segue.destinationViewController;
    controller.baby = self.baby;
    [controller setTotalSteps:self.totalSteps];
    [controller setCurrentStepNumber:self.currentStepNumber + 1];
}

@end
