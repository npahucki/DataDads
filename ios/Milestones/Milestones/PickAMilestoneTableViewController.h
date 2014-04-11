//
//  PickAMilestoneTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "Baby.h"
#import "StandardMilestone.h"
#import "MBProgressHUD.h"
#import "SWTableViewCell.h"


@protocol PickAMilestoneTableViewControllerDelegate <NSObject>

-(void) standardMilestoneIgnoreClicked:(StandardMilestone*) milestone;
-(void) standardMilestonePostponeClicked:(StandardMilestone*) milestone;
-(void) standardMilestoneCompleteClicked:(StandardMilestone*) milestone;
-(void) standardMilestoneDetailsClicked:(StandardMilestone*) milestone;

@end

@interface PickAMilestoneTableViewController : PFQueryTableViewController <SWTableViewCellDelegate>

@property (nonatomic, weak) id <PickAMilestoneTableViewControllerDelegate> delegate;

@end

MBProgressHUD * _hud;
NSIndexPath *_lastPageTriggeredBy;
