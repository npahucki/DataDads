//
//  NotificationTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "SWTableViewCell.h"

@interface NotificationTableViewController : UITableViewController <SWTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource>

@property TipType tipFilter;

- (void)loadObjects;

@end
