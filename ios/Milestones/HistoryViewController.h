//
//  HistoryViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>
#import "HistoryViewControllerDataSource.h"

@protocol HistoryViewControllerDelegate <NSObject>

- (void)standardMilestoneClicked:(StandardMilestone *)milestone;

- (void)achievementClicked:(MilestoneAchievement *)achievement;

@end


@interface HistoryViewController : UITableViewController <UITableViewDelegate, HistoryViewTableModelDelegate, SWTableViewCellDelegate, UIScrollViewDelegate>

@property(nonatomic, weak) id <HistoryViewControllerDelegate> delegate;
@property NSString *filterString;
@property(readonly) HistoryViewTableModel *model;

@end


