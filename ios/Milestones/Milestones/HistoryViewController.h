//
//  HistoryViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "AppQueryTableViewController.h"
#import "HistoryViewTableModel.h"
#import "SWTableViewCell.h"

@interface HistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, HistoryViewTableModelDelegate, SWTableViewCellDelegate>

@end

@interface LoadingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@end


@interface HistoryTableViewCell : SWTableViewCell

@property (nonatomic, strong) UIView* topLineView;
@property (nonatomic, strong) UIView* bottomLineView;
@end
