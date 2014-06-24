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



#define IMG_SIZE CGSizeMake(53,53)

@interface HistoryTableViewCell : SWTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *customImageView;

@property (nonatomic, strong) UIView* topLineView;
@property (nonatomic, strong) UIView* bottomLineView;
@end

@interface LoadingTableViewCell : HistoryTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
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
