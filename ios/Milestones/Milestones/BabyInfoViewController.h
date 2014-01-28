//
//  BabyInfoViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BabyInfoViewController : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *dobTextField;
@property (strong, nonatomic) IBOutlet UITextField *dueDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *babyName;
@property (strong, nonatomic) IBOutlet UISegmentedControl *genderControl;

@end
