//
//  HIstoryViewTableCells.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/25/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "RangeIndicatorView.h"

#define IMG_SIZE CGSizeMake(53,53)


@interface HistoryTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;
@property BOOL topLineHidden;
@property BOOL bottomLineHidden;

@end

@interface AchievementTableViewCell : HistoryTableViewCell

@property (nonatomic, weak) MilestoneAchievement * achievement;
@property (weak, nonatomic) IBOutlet UILabel *achievementDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *achievementTitleLabel;

@end


@interface MilestoneTableViewCell : HistoryTableViewCell


@property (nonatomic, weak) StandardMilestone * milestone;
@property (weak, nonatomic) IBOutlet UILabel *milestoneTitleLabel;

@end

@interface LoadingTableViewCell : HistoryTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@end


