//
//  NoteMilestoneSharingOptionsViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideOverViewController.h"
#import "MBContactPicker.h"

@class NoteMilestoneViewController;

@interface NoteMilestoneSharingOptionsViewController : UIViewController <MBContactPickerDelegate>
@property(weak, nonatomic) IBOutlet UISwitch *enableFacebookButton;
@property(weak, nonatomic) IBOutlet UISwitch *enableFollowersSwitch;
@property(weak, nonatomic) IBOutlet UILabel *selectFollowersLabel;
@property(weak, nonatomic) IBOutlet UILabel *friendsAndFamilyLabel;
@property(weak, nonatomic) IBOutlet UILabel *onFacebookLabel;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *pickerHeightConstraint;
@property(weak, nonatomic) IBOutlet UIButton *inviteButton;
@property(weak, nonatomic) IBOutlet MBContactPicker *pickerView;
@property(strong, nonatomic) MilestoneAchievement *achievement;

- (void)updateAchievementSharingOptions;
@end
