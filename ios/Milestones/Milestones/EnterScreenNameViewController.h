//
//  EnterScreenNameViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EnterScreenNameViewController : UIViewController 

@property (strong, nonatomic) IBOutlet UITextField *screenNameField;
@property (strong, nonatomic) IBOutlet UIButton *maleButton;
@property (strong, nonatomic) IBOutlet UIButton *femaleButton;
@property (strong, nonatomic) IBOutlet UILabel *maleLabel;
@property (strong, nonatomic) IBOutlet UILabel *femaleLabel;
@property (weak, nonatomic) IBOutlet UIButton *keepAnonymousButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;


@end
