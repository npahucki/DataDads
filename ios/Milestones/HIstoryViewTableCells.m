//
//  HistoryViewTableCells.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/25/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "HIstoryViewTableCells.h"
#import "NSDate+HumanizedTime.h"

@implementation HistoryTableViewCell
@end

@implementation LoadingTableViewCell

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    self.loadingLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
}

@end


@implementation AchievementTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Delete"];
    self.rightUtilityButtons = rightUtilityButtons;
    [self resetPicture];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    // This must be done here, as the UIAppearance overrides any values set in the awakeFromNib,
    // and using layoutViews causes an infinite triggering of view layouts because of some logic in the SWTableCell
    self.achievementDateLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetPicture];
}

- (void)resetPicture {
    self.pictureView.image = [UIImage imageNamed:@"historyNoPic"]; // use in case of error
    self.pictureView.alpha = 0.5;
    self.pictureView.contentMode = UIViewContentModeCenter;
}

- (void)setAchievement:(MilestoneAchievement *)achievement {
    _achievement = achievement;

    self.achievementDateLabel.text = [achievement.completionDate stringWithHumanizedTimeDifference];
    self.achievementTitleLabel.text = achievement.displayTitle;
    self.accessibilityIdentifier = self.achievementTitleLabel.text;
    PFFile *imageFile = achievement.attachmentThumbnail ? achievement.attachmentThumbnail : Baby.currentBaby.avatarImageThumbnail;
    if (imageFile) {
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [[UIImage alloc] initWithData:data];
                // NOTE: Image will be null if the image data is bad, which can happen for example if parse returns a 200 code but error text instead.
                if (image) {
                    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
                    self.pictureView.image = image;
                    self.pictureView.alpha = achievement.attachmentThumbnail ? 1.0 : 0.3;
                }
            }
        }];
    }
}


@end

@implementation MilestoneTableViewCell {
    RangeIndicatorView *_rangeView;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    _rangeView.frame = self.pictureView.frame;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    _rangeView = [[RangeIndicatorView alloc] initWithFrame:CGRectZero];
    _rangeView.rangeScale = RANGE_INDICATOR_SCALE;
    [self.contentView insertSubview:_rangeView belowSubview:self.pictureView];

    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor appNormalColor] title:@"Ignore"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor appSelectedColor] title:@"Postpone"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor appHeaderBackgroundActiveColor] title:@"Note It"];
    self.rightUtilityButtons = rightUtilityButtons;

}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)setMilestone:(StandardMilestone *)milestone {
    _milestone = milestone;
    self.milestoneTitleLabel.text = milestone.titleForCurrentBaby;
    self.accessibilityIdentifier = self.milestoneTitleLabel.text;
    _rangeView.startRange = milestone.rangeLow.integerValue;
    _rangeView.endRange = milestone.rangeHigh.integerValue;
}


@end
