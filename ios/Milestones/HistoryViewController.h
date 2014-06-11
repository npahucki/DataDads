//
//  HistoryViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "AppQueryTableViewController.h"
#import "HistoryViewControllerDataSource.h"

@protocol HistoryViewControllerDelegate <NSObject>

-(void) standardMilestoneClicked:(StandardMilestone*) milestone;
-(void) achievementClicked:(MilestoneAchievement*) achievement;

@end

@interface HistoryViewController : UITableViewController <UITableViewDelegate, HistoryViewTableModelDelegate, SWTableViewCellDelegate>

@property (nonatomic, weak) id <HistoryViewControllerDelegate> delegate;

@end


