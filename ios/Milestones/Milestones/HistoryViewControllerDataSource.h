//
//  HistoryViewControllerDataSource.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HistoryViewTableModel.h"
#import "SWTableViewCell.h"
#import "NSDate+HumanizedTime.h"



#define IMG_SIZE CGSizeMake(54,54)
#define PRELOAD_START_AT_IDX 3

@interface LoadingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@end


@interface HistoryTableViewCell : SWTableViewCell

@property (nonatomic, strong) UIView* topLineView;
@property (nonatomic, strong) UIView* bottomLineView;
@end

@interface HistoryViewControllerDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) HistoryViewTableModel * model;
@property (nonatomic, strong) id <SWTableViewCellDelegate> cellSwipeDelegate;

typedef NS_ENUM(NSInteger, HistorySectionType) {
  FutureMilestoneSection,
  AchievementSection,
  PastMilestoneSection
};



@end
