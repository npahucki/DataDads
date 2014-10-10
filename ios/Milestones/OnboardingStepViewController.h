//
//  OnboardingStepViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/10/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UIViewControllerWithHUDProgress.h"

@protocol ViewControllerWithBaby
@required

- (void)setBaby:(Baby *)baby;

- (void)setTotalSteps:(NSInteger)totalSteps;

- (void)setCurrentStepNumber:(NSInteger)currentStepNumber;

@end

@interface OnboardingStepViewController : UIViewControllerWithHUDProgress <ViewControllerWithBaby>

@property Baby *baby;
@property NSInteger totalSteps;
@property NSInteger currentStepNumber;


@end
