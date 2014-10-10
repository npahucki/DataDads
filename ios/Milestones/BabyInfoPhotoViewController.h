//
//  BabyInfoPhotoControllerViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UIViewControllerWithHUDProgress.h"
#import "FDTakeController.h"
#import "BabyInfoViewController.h"
#import "OnboardingStepViewController.h"


@interface BabyInfoPhotoViewController : OnboardingStepViewController <FDTakeDelegate>

@property(strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property(strong, nonatomic) IBOutlet UILabel *theLabel;


@end
