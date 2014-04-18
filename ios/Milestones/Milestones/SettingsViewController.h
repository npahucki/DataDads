//
//  SettingsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *babyNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@property (strong, nonatomic) IBOutlet PFImageView *babyAvatar;
@property (strong, nonatomic) IBOutlet UILabel *milestoneCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *historyButton;

@end


