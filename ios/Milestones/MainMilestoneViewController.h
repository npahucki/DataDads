//
//  MainMilestoneViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryViewController.h"
#import "MilestoneAchievement.h"

@interface MainMilestoneViewController : UIViewController <HistoryViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *addMilestoneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIButton *warningMsgButton;

@end

