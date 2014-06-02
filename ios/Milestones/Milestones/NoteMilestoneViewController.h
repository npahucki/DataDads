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


@interface NoteMilestoneViewController : UIViewControllerWithHUDProgress <FDTakeDelegate,UITextFieldDelegate, UITextViewDelegate>

@property MilestoneAchievement *achievement;
@property (strong, nonatomic) IBOutlet UIDateField *completionDateTextField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *commentsTextField;
@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (weak, nonatomic) IBOutlet UITextField *customTitleTextField;


@end

