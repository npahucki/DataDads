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

@interface MainMilestoneViewController : UIViewController <HistoryViewControllerDelegate,UISearchBarDelegate,UICollisionBehaviorDelegate>
@property (weak, nonatomic) IBOutlet UIButton *babyMenuButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addMilestoneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButton;

@end

