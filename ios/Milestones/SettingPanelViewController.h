//
//  SettingPanelViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "hipmob/HMChatView.h"
#import "SlideOverViewController.h"

@interface SettingPanelViewController : UITableViewController <HMChatOperatorAvailabilityCheckDelegate>
@property(weak, nonatomic) IBOutlet UISwitch *useMetricSwitch;
@property(weak, nonatomic) IBOutlet UISwitch *showIgnoredMilestonesSwitch;
@property(weak, nonatomic) IBOutlet UISwitch *showHiddenTipsSwitch;
@property(weak, nonatomic) IBOutlet UISwitch *showPostponedMilestonesSwitch;
@property(weak, nonatomic) IBOutlet UISwitch *showMilestoneStatisticsSwitch;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property(weak, nonatomic) IBOutlet UIImageView *liveChatStatus;
@property(weak, nonatomic) IBOutlet UIButton *earlyReaderButton;

@property(weak, nonatomic) IBOutlet UIButton *liveChatButton;
@end
