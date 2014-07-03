//
//  SettingPanelViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingPanelViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISwitch *useMetricSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *automaticallyShareOnFacebookSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *showIgnoredMilestonesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *showHiddenTipsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *showPostponedMilestonesSwitch;

@end
