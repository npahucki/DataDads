//
//  MilestoneNotedViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "StandardMilestone.h"
#import "FDTakeController.h"
#import "UIDateField.h"
#import "UIViewControllerWithHUDProgress.h"


@interface NoteMilestoneViewController : UIViewControllerWithHUDProgress <FDTakeDelegate>


@property (strong, nonatomic) IBOutlet UIDateField *completionDateTextField;

@property MilestoneAchievement *achievement;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (strong, nonatomic) IBOutlet UILabel *takePhotoLabel;

@end

