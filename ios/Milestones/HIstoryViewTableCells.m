//
//  HIstoryViewTableCells.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/25/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "HIstoryViewTableCells.h"
#import "NSDate+HumanizedTime.h"


#define CIRCLE_OFFSET 8
#define CIRCLE_COLOR [UIColor appGreyTextColor]
#define RANGE_INDICATOR_SCALE 365 * 5

@implementation HistoryTableViewCell {
    UIView *_topLineView;
    UIView *_bottomLineView;
    UIView *_circleView;
}

+ (void)initialize {
    [[UIButton appearanceWhenContainedIn:[SWTableViewCell class], nil] setTitleColor:[UIColor appGreyTextColor] forState:UIControlStateNormal];
    [UILabel appearanceWhenContainedIn:[SWTableViewCell class], nil].font = [UIFont fontForAppWithType:Medium andSize:13];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;

    _circleView.frame = CGRectInset(self.pictureView.frame, -CIRCLE_OFFSET, -CIRCLE_OFFSET);
    _circleView.layer.cornerRadius = _circleView.frame.size.width / 2;
    _topLineView.frame = CGRectMake(_circleView.frame.origin.x + _circleView.frame.size.width / 2, 0, 1, _circleView.frame.origin.y + 1);
    _bottomLineView.frame = CGRectMake(_circleView.frame.origin.x + _circleView.frame.size.width / 2, (_circleView.frame.origin.y + _circleView.frame.size.height) - 1, 1, (self.frame.size.height - (_circleView.frame.origin.y + _circleView.frame.size.height)) + 1);
}


- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.hidden = YES;
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;


    self.pictureView.layer.masksToBounds = YES;

    _circleView = [[UIView alloc] initWithFrame:CGRectZero];
    _circleView.layer.borderColor = CIRCLE_COLOR.CGColor;
    _circleView.layer.borderWidth = 1;
    [self.contentView addSubview:_circleView];

    _topLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _topLineView.backgroundColor = CIRCLE_COLOR;
    [self.contentView addSubview:_topLineView];

    _bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomLineView.backgroundColor = CIRCLE_COLOR;
    [self.contentView addSubview:_bottomLineView];
}

- (void)setTopLineHidden:(BOOL)topLineHidden {
    _topLineView.hidden = topLineHidden;
}

- (BOOL)topLineHidden {
    return _topLineView.hidden;
}

- (void)setBottomLineHidden:(BOOL)bottomLineHidden {
    _bottomLineView.hidden = bottomLineHidden;
}

- (BOOL)bottomLineHidden {
    return _bottomLineView.hidden;
}

@end


@implementation LoadingTableViewCell
- (void)layoutSubviews {
    [super layoutSubviews];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    self.achievementDateLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
    self.achievementTitleLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
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
    // For some reason, setitng this in awakeFromNib has no effect at all!
    self.milestoneTitleLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
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
    _rangeView.startRange = milestone.rangeLow.integerValue;
    _rangeView.endRange = milestone.rangeHigh.integerValue;
}


@end
