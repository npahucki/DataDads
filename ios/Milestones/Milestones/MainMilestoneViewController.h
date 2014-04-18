//
//  MainMilestoneViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickAMilestoneTableViewController.h"
#import "MilestoneAchievement.h"

@interface MainMilestoneViewController : UIViewController <PickAMilestoneTableViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *addMilestoneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

// Show an animation of the add button bouncing 3 time, to get attention
-(void) bounceAddButton;

@end

MilestoneAchievement * _currentAchievment;
PickAMilestoneTableViewController * _pickController;

BOOL _isMorganTouch;
