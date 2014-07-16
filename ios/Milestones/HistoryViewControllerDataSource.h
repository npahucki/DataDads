//
//  HistoryViewControllerDataSource.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/4/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HistoryViewTableModel.h"
#import "SWTableViewCell.h"
#import "NSDate+HumanizedTime.h"
#import "RangeIndicatorView.h"
#import "HIstoryViewTableCells.h"


@interface HistoryViewControllerDataSource : NSObject <UITableViewDataSource>

@property(nonatomic, strong) HistoryViewTableModel *model;
@property(nonatomic, strong) id <SWTableViewCellDelegate> cellSwipeDelegate;

typedef NS_ENUM(NSInteger, HistorySectionType) {
    FutureMilestoneSection,
    AchievementSection,
    PastMilestoneSection
};

@end

