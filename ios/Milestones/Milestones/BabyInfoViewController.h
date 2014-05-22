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
#import "UIDateField.h"

@protocol ViewControllerWithBaby
@required

-(void) setBaby:(Baby*)baby;

@end

@interface BabyInfoViewController : UIViewController <UITextFieldDelegate, ViewControllerWithBaby>


@property Baby* baby;

@property (strong, nonatomic) IBOutlet UIDateField *dobTextField;
@property (strong, nonatomic) IBOutlet UIDateField *dueDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *babyName;
@property (strong, nonatomic) IBOutlet UIButton *maleButton;
@property (strong, nonatomic) IBOutlet UIButton *femaleButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@property (strong, nonatomic) IBOutlet UILabel *maleLabel;
@property (strong, nonatomic) IBOutlet UILabel *femaleLabel;

@end


