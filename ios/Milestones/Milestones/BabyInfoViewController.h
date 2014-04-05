//
//  BabyInfoViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerWithHUDProgress.h"
#import "BabyTagsTableViewController.h"

@interface BabyInfoViewController : UIViewControllerWithHUDProgress <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *dobTextField;
@property (strong, nonatomic) IBOutlet UITextField *dueDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *babyName;
@property (strong, nonatomic) IBOutlet UIButton *maleButton;
@property (strong, nonatomic) IBOutlet UIButton *femaleButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;


@end


