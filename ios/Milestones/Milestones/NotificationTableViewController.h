//
//  NotificationTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AppQueryTableViewController.h"
#import "SWTableViewCell.h"

@interface NotificationTableViewController : AppQueryTableViewController <SWTableViewCellDelegate>

@property TipType tipFilter;

@end
