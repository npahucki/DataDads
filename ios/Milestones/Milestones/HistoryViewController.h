//
//  HistoryViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "AppQueryTableViewController.h"
@interface HistoryViewController : AppQueryTableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sortButton;
@property BOOL reverseSort;

@end

@interface HistoryTableViewCell : UITableViewCell

- (void)setAppearanceWithBlock:(void (^)())appearanceBlock force:(BOOL)force;

@property (nonatomic, strong) UIView* topLineView;
@property (nonatomic, strong) UIView* bottomLineView;
@end

BOOL _reverseSort;

static NSDateFormatter * _dateFormatter;