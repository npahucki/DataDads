//
//  EnterScreenNameViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BabyInfoViewController.h"
#import "UIViewControllerWithHUDProgress.h"

@interface EnterScreenNameViewController : UIViewControllerWithHUDProgress<ViewControllerWithBaby>

@property Baby* baby;

@property (strong, nonatomic) IBOutlet UITextField *screenNameField;
@property (strong, nonatomic) IBOutlet UIButton *maleButton;
@property (strong, nonatomic) IBOutlet UIButton *femaleButton;
@property (strong, nonatomic) IBOutlet UILabel *maleLabel;
@property (strong, nonatomic) IBOutlet UILabel *femaleLabel;
@property (weak, nonatomic) IBOutlet UIButton *acceptTACButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptTACLabelButton;


@end
