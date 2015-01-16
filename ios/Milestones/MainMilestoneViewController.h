//
//  MainMilestoneViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryViewController.h"
#import "MilestoneAchievement.h"
#import "DataParentingAdView.h"
#import "ViewControllerWithBabyInfoButton.h"

@interface MainMilestoneViewController : ViewControllerWithBabyInfoButton <HistoryViewControllerDelegate, UISearchBarDelegate, UICollisionBehaviorDelegate, DataParentingAdViewDelegate, UIDynamicAnimatorDelegate>

@property(weak, nonatomic) IBOutlet UIBarButtonItem *addMilestoneButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property(weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property(strong, nonatomic) UIBarButtonItem *searchButton;

@end

