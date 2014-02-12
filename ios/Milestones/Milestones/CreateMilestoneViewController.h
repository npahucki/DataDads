//
//  CreateMilestoneViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DESCRIPTION_PLACEHOLDER_TEXT @"Description..."

@interface CreateMilestoneViewController : UIViewController <UITextViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@property MilestoneAchievement *achievement;


@end

BOOL _descriptionDirty;
