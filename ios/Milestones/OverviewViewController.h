//
//  SettingsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OverviewViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *babyNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@property (strong, nonatomic) IBOutlet PFImageView *babyAvatar;
@property (weak, nonatomic) IBOutlet UIButton *logOutOrSignUpButton;
@property (strong, nonatomic) UILabel *milestoneCountLabel;
@property NSInteger milestoneCount;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@end


